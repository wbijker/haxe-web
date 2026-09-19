package codequery.migrations;

/**
	Enough YAML for a schema snapshot, and no more.

	Haxe has none in its standard library, and a snapshot is a small, closed shape: maps, lists,
	and scalars that are strings, numbers or booleans. Nothing here handles anchors, tags, flow
	collections or multi-document streams, because a snapshot has none of those — it is written by
	`SchemaSnapshot` and read back by it, and what it round-trips is what it needs to.
**/
class Yaml {
	/** A value as YAML. Maps and lists nest by indentation, two spaces a level. */
	public static function Emit(value:Dynamic):String {
		final out = new StringBuf();
		Write(out, value, 0, false);
		return out.toString();
	}

	static function Write(out:StringBuf, value:Dynamic, depth:Int, inList:Bool):Void {
		final pad = StringTools.rpad("", " ", depth * 2);

		if (Std.isOfType(value, Array)) {
			final items:Array<Dynamic> = value;
			if (items.length == 0) {
				out.add('$pad[]\n');
				return;
			}
			for (item in items) {
				out.add('$pad- ');
				WriteInline(out, item, depth + 1);
			}
			return;
		}

		if (Reflect.isObject(value) && !Std.isOfType(value, String)) {
			for (name in Reflect.fields(value)) {
				final held = Reflect.field(value, name);
				if (IsScalar(held)) {
					out.add('$pad$name: ${Scalar(held)}\n');
				} else {
					out.add('$pad$name:\n');
					Write(out, held, depth + 1, false);
				}
			}
			return;
		}

		out.add('$pad${Scalar(value)}\n');
	}

	/** A list item starts on the dash's own line, and what follows it lines up under it. */
	static function WriteInline(out:StringBuf, value:Dynamic, depth:Int):Void {
		if (IsScalar(value)) {
			out.add('${Scalar(value)}\n');
			return;
		}

		final rendered = new StringBuf();
		Write(rendered, value, depth, true);
		final lines = rendered.toString().split("\n");
		out.add(StringTools.ltrim(lines[0]) + "\n");
		for (index in 1...lines.length) {
			if (lines[index] != "") {
				out.add(lines[index] + "\n");
			}
		}
	}

	static function IsScalar(value:Dynamic):Bool {
		return value == null
			|| Std.isOfType(value, String)
			|| Std.isOfType(value, Int)
			|| Std.isOfType(value, Float)
			|| Std.isOfType(value, Bool);
	}

	static function Scalar(value:Dynamic):String {
		if (value == null) {
			return "null";
		}
		if (Std.isOfType(value, Bool) || Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return Std.string(value);
		}

		final text = Std.string(value);
		// Quoted where it would otherwise read as something else, or as nothing.
		final plain = ~/^[A-Za-z_][A-Za-z0-9_.\-]*$/;
		return plain.match(text) && text != "null" && text != "true" && text != "false"
			? text
			: '"' + StringTools.replace(StringTools.replace(text, "\\", "\\\\"), '"', '\\"') + '"';
	}

	/** YAML back to the maps, lists and scalars it was written from. */
	public static function Parse(yaml:String):Dynamic {
		final lines = [
			for (line in yaml.split("\n"))
				if (StringTools.trim(line) != "" && !StringTools.startsWith(StringTools.trim(line), "#")) line
		];
		final at = {index: 0};
		return ParseBlock(lines, at, Indent(lines[0]));
	}

	static function ParseBlock(lines:Array<String>, at:{index:Int}, depth:Int):Dynamic {
		if (at.index >= lines.length) {
			return null;
		}

		if (StringTools.startsWith(StringTools.ltrim(lines[at.index]), "- ")
			|| StringTools.trim(lines[at.index]) == "-") {
			final items:Array<Dynamic> = [];
			while (at.index < lines.length && Indent(lines[at.index]) == depth
				&& StringTools.startsWith(StringTools.ltrim(lines[at.index]), "-")) {
				final rest = StringTools.trim(lines[at.index]).substr(1);
				at.index++;
				if (StringTools.trim(rest) == "") {
					items.push(ParseBlock(lines, at, Indent(lines[at.index])));
					continue;
				}
				// The first member sits on the dash's line; the rest are indented under it.
				final head = StringTools.trim(rest);
				if (head.indexOf(":") < 0) {
					items.push(ScalarOf(head));
					continue;
				}
				final held:Dynamic = {};
				ReadPair(head, held, lines, at);
				while (at.index < lines.length && Indent(lines[at.index]) > depth) {
					ReadPair(StringTools.trim(lines[at.index++]), held, lines, at);
				}
				items.push(held);
			}
			return items;
		}

		if (StringTools.trim(lines[at.index]) == "[]") {
			at.index++;
			return [];
		}

		final held:Dynamic = {};
		while (at.index < lines.length && Indent(lines[at.index]) == depth) {
			ReadPair(StringTools.trim(lines[at.index++]), held, lines, at);
		}
		return held;
	}

	static function ReadPair(text:String, into:Dynamic, lines:Array<String>, at:{index:Int}):Void {
		final colon = text.indexOf(":");
		if (colon < 0) {
			return;
		}
		final name = StringTools.trim(text.substr(0, colon));
		final rest = StringTools.trim(text.substr(colon + 1));

		// A literal block: the lines indented under the key, as they were written.
		if (rest == "|") {
			final depth = Indent(lines[at.index - 1]);
			final held = [];
			while (at.index < lines.length && Indent(lines[at.index]) > depth) {
				held.push(lines[at.index++]);
			}
			final inner = held.length == 0 ? 0 : Indent(held[0]);
			Reflect.setField(into, name, [for (line in held) line.substr(inner)].join("\n"));
			return;
		}

		if (rest != "") {
			Reflect.setField(into, name, ScalarOf(rest));
			return;
		}
		Reflect.setField(into, name, at.index < lines.length ? ParseBlock(lines, at, Indent(lines[at.index])) : null);
	}

	static function ScalarOf(text:String):Dynamic {
		if (text == "null") {
			return null;
		}
		if (text == "true") {
			return true;
		}
		if (text == "false") {
			return false;
		}
		if (StringTools.startsWith(text, '"')) {
			final inner = text.substr(1, text.length - 2);
			return StringTools.replace(StringTools.replace(inner, '\\"', '"'), "\\\\", "\\");
		}
		final number = Std.parseInt(text);
		if (number != null && Std.string(number) == text) {
			return number;
		}
		return text;
	}

	static function Indent(line:String):Int {
		var spaces = 0;
		while (spaces < line.length && line.charAt(spaces) == " ") {
			spaces++;
		}
		return spaces;
	}
}
