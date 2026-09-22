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
	up clause by clause comes out as `$db->Bookings->From()->Where(…)->Select(…)` — one line that
	is hard to read as the chain it is. This runs after generation and breaks that line before
	every `->` past the first, indented a step in from the statement:

	```
	$rows = Main::$db->Bookings
		->From()
		->Where(function ($b) {
			return Expr::greaterThan($b->price->zar, Expr::constInt(100));
		})
		->Fetch();
	```

	A clause compiled to a callback spreads its statement over several lines — the closure's body
	has lines of its own — so a statement is read whole, until its brackets balance, and the lines
	inside it move in a step with the chain they now hang from.

	Only whitespace is touched, only outside string literals, and only where the `->` is at the
	top level of the statement — one nested in a call's arguments stays where it is.

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
		final lines = source.split("\n");
		final out:Array<String> = [];
		var i = 0;
		while (i < lines.length) {
			final line = lines[i];
			if (!IsCode(line)) {
				out.push(line);
				i++;
				continue;
			}
			// A statement runs on while its brackets are open — a closure's body, a list of arguments.
			final statement = [line];
			var depth = Depth(line);
			while (depth > 0 && i + 1 < lines.length) {
				i++;
				statement.push(lines[i]);
				depth += Depth(lines[i]);
			}
			out.push(Statement(statement));
			i++;
		}
		return out.join("\n");
	}

	/** A position directive, a comment or a blank line is not code. */
	static function IsCode(line:String):Bool {
		final trimmed = StringTools.ltrim(line);
		return trimmed != "" && trimmed.charAt(0) != "#" && !StringTools.startsWith(trimmed, "//")
			&& !StringTools.startsWith(trimmed, "*") && !StringTools.startsWith(trimmed, "/*");
	}

	/** How many more brackets and parentheses a line opens than it closes, outside strings. */
	static function Depth(line:String):Int {
		if (!IsCode(line)) {
			return 0;
		}
		var depth = 0;
		var quote:Null<String> = null;
		var i = 0;
		while (i < line.length) {
			final c = line.charAt(i);
			if (quote != null) {
				if (c == "\\") {
					i += 2;
					continue;
				}
				if (c == quote) {
					quote = null;
				}
			} else {
				switch c {
					case "'" | '"': quote = c;
					case "(" | "[": depth++;
					case ")" | "]": depth--;
					case _:
				}
			}
			i++;
		}
		return depth;
	}

	/**
		One statement, laid out. Its lines are read as one text, the chain breaks found at the
		text's top level, and each original line past a break moved in a step, since it now hangs
		from a continuation line rather than the statement's first.
	**/
	static function Statement(lines:Array<String>):String {
		final first = lines[0];
		final trimmed = StringTools.ltrim(first);
		final indent = first.substr(0, first.length - trimmed.length);
		final text = [trimmed].concat(lines.slice(1)).join("\n");

		// A comment line inside the statement is not code; blanked for the analysis, kept for the output.
		final analysed = text.split("\n").map(line -> IsCode(line) ? line : Blank(line)).join("\n");
		final breaks:Array<Int> = [];
		for (chain in Chains(analysed)) {
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
			return lines.join("\n");
		}

		final out = new StringBuf();
		out.add(indent);
		var broken = false;
		var next = 0;
		for (i in 0...text.length) {
			if (next < breaks.length && breaks[next] == i) {
				out.add("\n" + indent + "\t");
				broken = true;
				next++;
			}
			final c = text.charAt(i);
			out.add(c);
			// An original line past a break moves in a step with the chain it hangs from.
			if (c == "\n" && broken) {
				out.add("\t");
			}
		}
		return out.toString();
	}

	static function Blank(line:String):String {
		return StringTools.rpad("", " ", line.length);
	}

	/**
		The chains in a text: each run of `->` accesses on one receiver, outside strings and at the
		top level of the text's brackets. A space, an operator or a comma at that level ends one.
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
				case " " | "\t" | "\n" | "=" | "," | ";" | "." | "+" | "?" | ":" | "!" | "&" | "|" | "<" | ">" if (depth == 0):
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
