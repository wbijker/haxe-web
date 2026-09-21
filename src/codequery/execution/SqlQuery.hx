package codequery.execution;

import codequery.sqlexpressions.SqlConstValue;

/**
	A statement as it is sent: the SQL, the values beside it, and where in the code it was asked
	for — `CodeQuery.Execution.SqlQuery`. What a logger is handed.
**/
class SqlQuery {
	public final Sql:String;
	public final Parameters:Array<SqlConstValue>;

	/** The call site that asked for the statement, or null where the stack could not say. */
	public final Origin:Null<SourceLocation>;

	/** How the statement writes a value's placeholder, so `Inlined` can find them. */
	final placeholder:Int->String;

	public function new(statement:Statement, placeholder:Int->String, ?origin:SourceLocation) {
		this.Sql = statement.Sql;
		this.Parameters = statement.Parameters;
		this.placeholder = placeholder;
		this.Origin = origin;
	}

	/**
		The statement with its values written in where the placeholders were, so a line of a log
		can be copied out and run as it stands. What went to the database still binds them.
	**/
	public function Inlined():String {
		if (Parameters.length == 0) {
			return Sql;
		}
		// A placeholder is the same mark for every value (`?`), or numbered (`$1`, `$2`): the
		// first is replaced in order of appearance, the second by its number.
		final positional = placeholder(1) == placeholder(2);
		final out = new StringBuf();
		var next = 0;
		var i = 0;
		while (i < Sql.length) {
			final c = Sql.charAt(i);
			if (c == "'") {
				// A quoted string, with '' inside it, is copied whole.
				final close = ClosingQuote(i);
				out.add(Sql.substr(i, close - i + 1));
				i = close + 1;
				continue;
			}
			if (positional && Sql.substr(i, placeholder(1).length) == placeholder(1)) {
				out.add(Literal(next < Parameters.length ? Parameters[next] : SqlConstNull));
				next++;
				i += placeholder(1).length;
				continue;
			}
			if (!positional) {
				var matched = false;
				// The longest number first, so `$12` is not read as `$1` and a `2`.
				var n = Parameters.length;
				while (n >= 1) {
					final mark = placeholder(n);
					if (Sql.substr(i, mark.length) == mark) {
						out.add(Literal(Parameters[n - 1]));
						i += mark.length;
						matched = true;
						break;
					}
					n--;
				}
				if (matched) {
					continue;
				}
			}
			out.add(c);
			i++;
		}
		return out.toString();
	}

	function ClosingQuote(open:Int):Int {
		var i = open + 1;
		while (i < Sql.length) {
			if (Sql.charAt(i) == "'") {
				if (Sql.charAt(i + 1) == "'") {
					i += 2;
					continue;
				}
				return i;
			}
			i++;
		}
		return Sql.length - 1;
	}

	/**
		Where the statement was asked for: the nearest frame of the stack outside this library —
		the C# logger walks the stack the same way. Null where the runtime keeps no stack.
	**/
	public static function CallSite():Null<SourceLocation> {
		for (item in haxe.CallStack.callStack()) {
			switch item {
				case FilePos(frame, file, line, _) if (!IsLibrary(file)):
					final member = switch frame {
						case Method(className, methodName): '$className.$methodName';
						case _: null;
					}
					final source = HaxeSource(file, line);
					return {File: source.file, Line: source.line, Member: member};
				case _:
			}
		}
		return null;
	}

	/**
		The Haxe line a generated line came from, where the runtime's stack names generated code:
		the PHP the compiler writes carries a `#src/Main.hx:19: …` directive above each statement,
		and the nearest one above the frame's line is the statement that asked. Elsewhere the
		frame is the Haxe line already.
	**/
	static function HaxeSource(file:String, line:Int):{file:String, line:Int} {
		#if php
		if (!StringTools.endsWith(file, ".php") || !sys.FileSystem.exists(file)) {
			return {file: file, line: line};
		}
		final lines = sys.io.File.getContent(file).split("\n");
		var at = line - 1;
		while (at >= 0 && at < lines.length) {
			final directive = ~/^\s*#(.+?):(\d+):/;
			if (directive.match(lines[at])) {
				return {file: directive.matched(1), line: Std.parseInt(directive.matched(2))};
			}
			at--;
		}
		#end
		return {file: file, line: line};
	}

	static function IsLibrary(file:String):Bool {
		final path = StringTools.replace(file, "\\", "/");
		return path.indexOf("/codequery/") >= 0 || StringTools.startsWith(path, "codequery/") || path.indexOf("/haxe/") >= 0
			|| StringTools.startsWith(path, "haxe/") || StringTools.startsWith(path, "php/") || path.indexOf("/std/") >= 0;
	}

	/** A value as SQL writes it. */
	public static function Literal(value:SqlConstValue):String {
		return switch value {
			case SqlConstBool(v): v ? "TRUE" : "FALSE";
			case SqlConstInt(v): Std.string(v);
			case SqlConstFloat(v): Std.string(v);
			case SqlConstString(v): "'" + StringTools.replace(v, "'", "''") + "'";
			case SqlConstDate(v): "'" + DateTools.format(v, "%Y-%m-%d %H:%M:%S") + "'";
			case SqlConstNull: "NULL";
		}
	}
}
