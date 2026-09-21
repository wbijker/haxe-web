package codequery.php;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
#end

/**
	Lays a chain of calls out one per line in the PHP the compiler generates.

	The generator writes a statement on one line however it was written in Haxe, so a query built
	up clause by clause comes out as `$db->Bookings->Update()->WhereCondition(…)->SetColumn(…)` —
	one line that is hard to read as the chain it is. This runs after generation and breaks that
	line before every `->` past the first, indented a step in from the statement:

	```
	$repriced = Main::$db->Bookings
		->Update()
		->WhereCondition(…)
		->SetColumn(…);
	```

	Only whitespace is touched, only outside string literals, and only where the `->` is at the
	top level of the line — one nested in a call's arguments stays where it is.

	Registered from the build with `--macro codequery.php.ChainLayout.apply()`.
**/
class ChainLayout {
	#if macro
	public static function apply():Void {
		Context.onAfterGenerate(() -> {
			final output = Compiler.getOutput();
			if (output != null && FileSystem.exists(output)) {
				Walk(output);
			}
		});
	}

	static function Walk(directory:String):Void {
		for (name in FileSystem.readDirectory(directory)) {
			final path = '$directory/$name';
			if (FileSystem.isDirectory(path)) {
				Walk(path);
			} else if (StringTools.endsWith(name, ".php")) {
				final source = File.getContent(path);
				final laidOut = Reflow(source);
				if (laidOut != source) {
					File.saveContent(path, laidOut);
				}
			}
		}
	}
	#end

	/** The file's text with every top-level chain broken one call a line. */
	public static function Reflow(source:String):String {
		return source.split("\n").map(Line).join("\n");
	}

	static function Line(line:String):String {
		final trimmed = StringTools.ltrim(line);
		// A position directive or a comment is not code.
		if (trimmed == "" || trimmed.charAt(0) == "#" || StringTools.startsWith(trimmed, "//") || StringTools.startsWith(trimmed, "*")) {
			return line;
		}
		final indent = line.substr(0, line.length - trimmed.length);
		final breaks = [];
		for (chain in Chains(trimmed)) {
			// A chain worth laying out calls at least two methods; `$this->Configuration->Fetch(…)`
			// is a field and one call, and reads better as it is. The first arrow stays on the
			// line — `$db->Bookings` reads as one name — and every later one starts a line.
			if (chain.calls >= 2) {
				for (i in 1...chain.arrows.length) {
					breaks.push(chain.arrows[i]);
				}
			}
		}
		if (breaks.length == 0) {
			return line;
		}
		final out = new StringBuf();
		var from = 0;
		for (at in breaks) {
			out.add(trimmed.substr(from, at - from));
			out.add("\n" + indent + "\t");
			from = at;
		}
		out.add(trimmed.substr(from));
		return indent + out.toString();
	}

	/**
		The chains on a line: each run of `->` accesses on one receiver, outside strings and at the
		top level of the line's brackets. A space, an operator or a comma at that level ends one.
	**/
	static function Chains(code:String):Array<{arrows:Array<Int>, calls:Int}> {
		final chains = [];
		var current = {arrows: [], calls: 0};
		final close = () -> {
			if (current.arrows.length > 0) {
				chains.push(current);
			}
			current = {arrows: [], calls: 0};
		};
		var depth = 0;
		var quote:Null<String> = null;
		var i = 0;
		while (i < code.length) {
			final c = code.charAt(i);
			if (quote != null) {
				if (c == "\\") {
					i += 2;
					continue;
				}
				if (c == quote) {
					quote = null;
				}
				i++;
				continue;
			}
			switch c {
				case "'" | '"': quote = c;
				case "(" | "[" | "{": depth++;
				case ")" | "]" | "}": depth--;
				case "-" if (depth == 0 && code.charAt(i + 1) == ">"):
					current.arrows.push(i);
					if (IsCall(code, i + 2)) {
						current.calls++;
					}
					i += 2;
					continue;
				case " " | "\t" | "=" | "," | ";" | "." | "+" | "?" | ":" | "!" | "&" | "|" | "<" | ">" if (depth == 0):
					close();
				case _:
			}
			i++;
		}
		close();
		return chains;
	}

	/** Whether what follows an arrow is a method call — a name and then `(`. */
	static function IsCall(code:String, from:Int):Bool {
		var i = from;
		while (i < code.length && ~/[A-Za-z0-9_]/.match(code.charAt(i))) {
			i++;
		}
		return i > from && code.charAt(i) == "(";
	}

}
