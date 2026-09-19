package codequery.sqlexpressions;

import haxe.macro.Expr;
#if macro
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
#end

/**
	The part of the conversion that reads a call: the methods Haxe already has for a string and a
	date, `Math`, the functions C# names in `KnownFunctions`, a span of time, and an inline
	function — a piece of a query written as an ordinary function, expanded where it is called.

	`ExpressionConverter` asks here first for every expression it converts; what is not one of
	these answers null and is converted as before.
**/
@:access(codequery.sqlexpressions.ExpressionConverter)
class FunctionConverter {
	#if macro
	/** The locals of the inline functions being expanded, innermost last. */
	static final inlineLocals:Array<Array<String>> = [];

	/** The expression building the SQL for `e`, or null where `e` is none of this file's business. */
	public static function Convert(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Null<Expr> {
		final e = Strip(e);
		return switch e.expr {
			// `f(…).value`: the function's own expression, as the call is.
			case EField(inner, "value", _) if (IsInlineCall(inner)):
				ExpressionConverter.ToSqlExpression(inner, bound, rows);

			case ECall({expr: EField({expr: EConst(CIdent("Sql"))}, _, _)}, _)
				| ECall({expr: EField({expr: EField({expr: EConst(CIdent("codequery"))}, "Sql", _)}, _, _)}, _):
				null;

			case ECall(callee, args):
				Call(e, callee, args, bound, rows);

			// `new Date(y, m, d, h, mi, s)`: built from the row where it reads one, else the date it is.
			case ENew({name: "Date", pack: []}, args):
				MentionsRow(e, bound)
					? macro codequery.sqlexpressions.Expr.call(codequery.sqlexpressions.SqlFunctions.DateTimeFromParts,
						${Converted(args, bound, rows, e.pos)})
					: ExpressionConverter.Valued(e);

			// `a + b` over strings is concatenation, which is not what `+` means in SQL.
			case EBinop(OpAdd, left, right) if (IsString(left, bound, rows) || IsString(right, bound, rows)):
				macro codequery.sqlexpressions.Expr.call(codequery.sqlexpressions.SqlFunctions.Concat,
					[${ExpressionConverter.ToSqlExpression(left, bound, rows)}, ${ExpressionConverter.ToSqlExpression(right, bound, rows)}]);

			// `s.length` of a string column is a function of it, not a column of its own.
			case EField(owner, "length", _) if (IsString(owner, bound, rows)):
				Known(SqlFunctions.Length, [owner], bound, rows, e.pos);

			case EConst(CIdent(name)) if (!bound.exists(name) && name != "true" && name != "false" && name != "null"):
				Identifier(e, name);

			case _:
				null;
		}
	}

	/** A call that is not one of `Sql`'s. */
	static function Call(e:Expr, callee:Expr, args:Array<Expr>, bound:Map<String, Int>, rows:Array<Type>):Null<Expr> {
		final pos = e.pos;
		final expanded = InlineField(callee);
		if (expanded != null) {
			return ExpandInline(expanded, args, bound, rows, pos);
		}

		switch Strip(callee).expr {
			// `f(…).value`, as a typed body spells it.
			case EField(_, "get_value" | "toValue", _) if (args.length == 1 && IsInlineCall(args[0])):
				return ExpressionConverter.ToSqlExpression(args[0], bound, rows);

			case EField({expr: EConst(CIdent("Date"))}, "now", _):
				return Known(SqlFunctions.Now, [], bound, rows, pos);
			case EField({expr: EConst(CIdent("Date"))}, "fromString", _):
				return Known(SqlFunctions.Parse, args, bound, rows, pos);

			case EField({expr: EConst(CIdent("Math"))}, name, _):
				final known = switch name {
					case "abs": SqlFunctions.Abs;
					case "ceil" | "fceil": SqlFunctions.Ceiling;
					case "floor" | "ffloor": SqlFunctions.Floor;
					case "round" | "fround": SqlFunctions.Round;
					case "sqrt": SqlFunctions.Sqrt;
					case "exp": SqlFunctions.Exp;
					case "log": SqlFunctions.Ln;
					case "pow": SqlFunctions.Power;
					case "max": SqlFunctions.Greatest;
					case "min": SqlFunctions.Least;
					case _: Context.error('Math.$name has no SQL here', pos);
				}
				return Known(known, args, bound, rows, pos);

			// A conversion written as a call is a cast.
			case EField({expr: EConst(CIdent("Std"))}, "int", _):
				return macro codequery.sqlexpressions.Expr.castTo(${ExpressionConverter.ToSqlExpression(args[0], bound, rows)},
					codequery.sqlexpressions.SqlType.SqlInt);
			case EField({expr: EConst(CIdent("Std"))}, "string", _):
				return macro codequery.sqlexpressions.Expr.castTo(${ExpressionConverter.ToSqlExpression(args[0], bound, rows)},
					codequery.sqlexpressions.SqlType.SqlText);

			// `StringTools.trim(s)` is `s.trim()` written without `using`.
			case EField({expr: EConst(CIdent("StringTools"))}, method, _) if (args.length > 0):
				return Member(args[0], method, args.slice(1), bound, rows, pos);

			// A typed body spells an abstract's method as `SqlDate_Impl_.truncate(d, part)`.
			case EField({expr: EField(_, impl, _) | EConst(CIdent(impl))}, method, _)
				if (StringTools.endsWith(impl, "_Impl_") && args.length > 0):
				return Member(args[0], method, args.slice(1), bound, rows, pos);

			case _:
		}

		// A span of time that reads nothing of the row is a value now, and an interval in SQL.
		if (!MentionsRow(e, bound) && IsInterval(e)) {
			return macro codequery.sqlexpressions.Expr.interval($e);
		}

		return switch Strip(callee).expr {
			case EField(owner, method, _): Member(owner, method, args, bound, rows, pos);
			case _: null;
		}
	}

	/** A method of a string or a date, by its Haxe name. */
	static function Member(owner:Expr, method:String, args:Array<Expr>, bound:Map<String, Int>, rows:Array<Type>,
			pos:Position):Null<Expr> {
		final withOwner = (name:String) -> Known(name, [owner].concat(args), bound, rows, pos);
		final operand = () -> ExpressionConverter.ToSqlExpression(owner, bound, rows);
		final operation = (kind:String) -> {
			final type = macro $p{["codequery", "sqlexpressions", "StringOperationType", kind]};
			macro codequery.sqlexpressions.Expr.stringOperation(${operand()}, $type,
				${ExpressionConverter.ToSqlExpression(args[0], bound, rows)});
		};
		final dateOperation = (kind:String, part:Expr, ?other:Expr) -> {
			final op = macro $p{["codequery", "DateOperation", kind]};
			final unit = macro(${part} : codequery.DateTimePart);
			other == null
				? macro codequery.sqlexpressions.Expr.dateOperation($op, $unit, ${operand()})
				: macro codequery.sqlexpressions.Expr.dateOperation($op, $unit, ${operand()}, $other);
		};

		return switch method {
			// ---- strings ----
			case "toUpperCase": withOwner(SqlFunctions.Upper);
			case "toLowerCase": withOwner(SqlFunctions.Lower);
			case "trim": withOwner(SqlFunctions.Trim);
			case "ltrim": withOwner(SqlFunctions.TrimStart);
			case "rtrim": withOwner(SqlFunctions.TrimEnd);
			case "substr": withOwner(SqlFunctions.Substring);
			case "replace": withOwner(SqlFunctions.Replace);
			case "indexOf": Known(SqlFunctions.IndexOf, [owner, args[0]], bound, rows, pos);
			// Haxe pads with a character, SQL with a space unless told otherwise.
			case "lpad" | "rpad":
				final name = method == "lpad" ? SqlFunctions.PadLeft : SqlFunctions.PadRight;
				final padding = Strip(args[0]).expr.match(EConst(CString(" ", _))) ? [] : [args[0]];
				Known(name, [owner, args[1]].concat(padding), bound, rows, pos);
			case "contains": operation("Contains");
			case "startsWith": operation("StartsWith");
			case "endsWith": operation("EndsWith");

			// ---- dates ----
			case "getFullYear": withOwner(SqlFunctions.Year);
			case "getMonth": withOwner(SqlFunctions.Month);
			case "getDate": withOwner(SqlFunctions.Day);
			case "getHours": withOwner(SqlFunctions.Hour);
			case "getMinutes": withOwner(SqlFunctions.Minute);
			case "getSeconds": withOwner(SqlFunctions.Second);
			case "getDay": withOwner(SqlFunctions.DayOfWeek);
			case "dayOfYear": withOwner(SqlFunctions.DayOfYear);
			case "date": withOwner(SqlFunctions.Date);
			case "addYears": withOwner(SqlFunctions.AddYears);
			case "addMonths": withOwner(SqlFunctions.AddMonths);
			case "addDays": withOwner(SqlFunctions.AddDays);
			case "addHours": withOwner(SqlFunctions.AddHours);
			case "addMinutes": withOwner(SqlFunctions.AddMinutes);
			case "addSeconds": withOwner(SqlFunctions.AddSeconds);
			case "truncate": dateOperation("Truncate", args[0]);
			case "part": dateOperation("Part", args[0]);
			case "differenceTo": dateOperation("Difference", args[1], ExpressionConverter.ToSqlExpression(args[0], bound, rows));
			case "endOfMonth": dateOperation("EndOfMonth", macro codequery.DateTimePart.Day);
			case "epochSeconds": dateOperation("EpochSeconds", macro codequery.DateTimePart.Second);
			case "format": macro codequery.sqlexpressions.Expr.dateFormat(${operand()}, ${args[0]});

			case _: null;
		}
	}

	/** A call of one of `SqlFunctions`' names over converted arguments. */
	static function Known(name:String, args:Array<Expr>, bound:Map<String, Int>, rows:Array<Type>, pos:Position):Expr {
		return macro codequery.sqlexpressions.Expr.call($v{name}, ${Converted(args, bound, rows, pos)});
	}

	static function Converted(args:Array<Expr>, bound:Map<String, Int>, rows:Array<Type>, pos:Position):Expr {
		return {expr: EArrayDecl([for (arg in args) ExpressionConverter.ToSqlExpression(arg, bound, rows)]), pos: pos};
	}

	/**
		A name that is neither a row nor a literal: a local of an inline function being expanded,
		which is bound beside the statement; a variable captured from around the lambda, which is
		bound beside it too; a span, which is an interval.
	**/
	static function Identifier(e:Expr, name:String):Null<Expr> {
		var frame = inlineLocals.length - 1;
		while (frame >= 0) {
			if (inlineLocals[frame].indexOf(name) >= 0) {
				return macro codequery.sqlexpressions.Expr.paramOf($i{name});
			}
			frame--;
		}

		final typed = try Context.typeExpr(e) catch (_:Dynamic) return null;
		if (!typed.expr.match(TLocal(_))) {
			return null;
		}
		if (IsIntervalType(typed.t)) {
			return macro codequery.sqlexpressions.Expr.interval($e);
		}
		// A captured local is sent beside the statement as a parameter, which is what C# does with
		// a variable a lambda closes over; a static or a literal is written into it.
		return switch typed.t.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int" | "Float" | "Bool"}, _)
				| TInst(_.get() => {name: "String" | "Date"}, _):
				ExpressionConverter.ParameterisedAs(e, typed.t);
			case _: null;
		}
	}

	// ---- inline functions ----------------------------------------------------------------------

	/**
		The call is replaced by what the function returns, so the query says what writing it in place
		would. An argument that reads the row is carried whole into the function's expression; one
		that does not is computed when the query is built, as is everything the function does before
		`InlineFunction.create`, and reaches the SQL as a bound value.
	**/
	static function ExpandInline(field:ClassField, args:Array<Expr>, bound:Map<String, Int>, rows:Array<Type>,
			pos:Position):Expr {
		final typed = field.expr();
		if (typed == null) {
			Context.error('\'${field.name}\' has no body to expand', pos);
		}
		final fn = switch Context.getTypedExpr(typed).expr {
			case EFunction(_, f): f;
			case _: Context.error('\'${field.name}\' is not a function', pos);
		}
		if (fn.args.length != args.length) {
			Context.error('\'${field.name}\' takes ${fn.args.length} argument(s), not ${args.length}', pos);
		}

		final statements = switch Strip(fn.expr).expr {
			case EBlock(items): items.copy();
			case _: [fn.expr];
		}
		if (statements.length == 0) {
			Context.error('\'${field.name}\' returned no inline function.', pos);
		}
		final body = CreatedBody(statements.pop(), field.name, pos);

		// Arguments that read the row travel as expressions; the rest are values, computed now.
		final carried = new Map<String, Expr>();
		final locals:Array<String> = [];
		final prelude:Array<Expr> = [];
		for (index => arg in fn.args) {
			final given = args[index];
			if (MentionsRow(given, bound)) {
				carried.set(arg.name, {expr: EParenthesis(given), pos: given.pos});
			} else {
				locals.push(arg.name);
				prelude.push({expr: EVars([{name: arg.name, type: null, expr: given}]), pos: given.pos});
			}
		}

		for (statement in statements) {
			for (name in carried.keys()) {
				if (Mentions(statement, name)) {
					Context.error('\'${field.name}\' failed while the query was being built: it reads \'$name\' '
						+ 'before there is a row. An inline function runs before there is a row: inside '
						+ 'InlineFunction.create(() -> …) the row is only captured, which is fine, but reading it '
						+ 'outside cannot work.', pos);
				}
			}
			switch statement.expr {
				case EVars(vars):
					for (v in vars) {
						locals.push(v.name);
					}
				case _:
			}
			prelude.push(statement);
		}

		final used:Array<String> = [];
		final substituted = Substitute(body, carried, used);
		final unused = [for (name in carried.keys()) if (used.indexOf(name) < 0) "'" + name + "'"];
		if (unused.length > 0) {
			Context.error('\'${field.name}\' was given ${unused.join(", ")} from the query\'s row, but did not use it '
				+ 'inside InlineFunction.create(() -> …). A row-reading argument has no value while the query is '
				+ 'being built, so it can only be part of the expression — anything computed from it in Haxe would '
				+ 'be computed from nothing.', pos);
		}

		inlineLocals.push(locals);
		final converted = try {
			ExpressionConverter.ToSqlExpression(substituted, bound, rows);
		} catch (error:Dynamic) {
			inlineLocals.pop();
			throw error;
		}
		inlineLocals.pop();

		prelude.push(converted);
		return {expr: EBlock(prelude), pos: pos};
	}

	/** The expression inside `InlineFunction.create(() -> …)`, which is what the function stands for. */
	static function CreatedBody(returned:Expr, name:String, pos:Position):Expr {
		final call = switch Strip(returned).expr {
			case EReturn(inner) if (inner != null): Strip(inner);
			case _: Strip(returned);
		}
		return switch call.expr {
			case ECall({expr: EField(_, "create", _)}, [{expr: EFunction(_, lambda)}]):
				Clean(ExpressionConverter.Returned(Strip(lambda.expr)));
			case _:
				Context.error('\'$name\' returned no inline function.', pos);
		}
	}

	/** The caller's expressions put back where the function's parameters were read. */
	static function Substitute(e:Expr, carried:Map<String, Expr>, used:Array<String>):Expr {
		return switch e.expr {
			case EConst(CIdent(name)) if (carried.exists(name)):
				if (used.indexOf(name) < 0) {
					used.push(name);
				}
				carried.get(name);
			case _:
				ExprTools.map(e, inner -> Substitute(inner, carried, used));
		}
	}

	/**
		A typed body read back as syntax carries what typing added — casts, an abstract's method as a
		static call, an implicit conversion as an explicit one. Taken off again, so the body reads as
		it was written.
	**/
	static function Clean(e:Expr):Expr {
		return switch e.expr {
			case ECast(inner, _) | EMeta(_, inner) | ECheckType(inner, _) | EParenthesis(inner):
				Clean(inner);
			case ECall({expr: EField({expr: EField(_, impl, _) | EConst(CIdent(impl))}, "get_value" | "toValue", _)}, [inner])
				if (StringTools.endsWith(impl, "_Impl_")):
				Clean(inner);
			case ECall({expr: EField({expr: EField(_, impl, _) | EConst(CIdent(impl))}, method, _)}, args)
				if (StringTools.endsWith(impl, "_Impl_") && method != "create" && args.length > 0):
				{expr: ECall({expr: EField(Clean(args[0]), method), pos: e.pos}, [for (arg in args.slice(1)) Clean(arg)]), pos: e.pos};
			case _:
				ExprTools.map(e, Clean);
		}
	}

	/** The static function `callee` names, where it answers with an inline function; else null. */
	static function InlineField(callee:Expr):Null<ClassField> {
		final typed = try Context.typeExpr(callee) catch (_:Dynamic) return null;
		final field = switch typed.expr {
			case TField(_, FStatic(_, cf)): cf.get();
			case _: return null;
		}
		return switch field.type.follow() {
			case TFun(_, ret) if (IsInlineType(ret)): field;
			case _: null;
		}
	}

	static function IsInlineCall(e:Expr):Bool {
		return switch Strip(e).expr {
			case ECall(callee, _): InlineField(callee) != null;
			case _: false;
		}
	}

	static function IsInlineType(t:Type):Bool {
		return switch t.follow() {
			case TAbstract(_.get() => {name: "InlineFunction", pack: ["codequery"]}, _): true;
			case _: false;
		}
	}

	// ---- what an expression is ------------------------------------------------------------------

	static function IsInterval(e:Expr):Bool {
		final t = try Context.typeof(e) catch (_:Dynamic) return false;
		return IsIntervalType(t);
	}

	static function IsIntervalType(t:Type):Bool {
		return switch t.follow() {
			case TAbstract(_.get() => {name: "SqlInterval", pack: ["codequery"]}, _): true;
			case _: false;
		}
	}

	/** Whether an expression is a string: a literal, a string column, or a function of one. */
	static function IsString(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Bool {
		final e = Strip(e);
		return switch e.expr {
			case EConst(CString(_, _)): true;
			case EBinop(OpAdd, left, right): IsString(left, bound, rows) || IsString(right, bound, rows);
			case ECall({expr: EField(_, method, _)}, _):
				["toUpperCase", "toLowerCase", "trim", "ltrim", "rtrim", "substr", "replace", "lpad", "rpad", "format"]
					.indexOf(method) >= 0;
			case EField(_, _, _):
				final reached = ExpressionConverter.PathOf(e, bound);
				if (reached == null) {
					return false;
				}
				final row = rows[reached.row];
				if (ExpressionConverter.FieldsOf(row) == null) {
					return false;
				}
				try {
					ExpressionConverter.MemberTypeOf(reached.path, row, e.pos).follow().match(TInst(_.get() => {name: "String"}, _));
				} catch (_:Dynamic) {
					false;
				}
			case _: false;
		}
	}

	/** Whether the expression names one of the rows the lambda is written over. */
	static function MentionsRow(e:Expr, bound:Map<String, Int>):Bool {
		for (name in bound.keys()) {
			if (Mentions(e, name)) {
				return true;
			}
		}
		return false;
	}

	static function Mentions(e:Expr, name:String):Bool {
		var found = false;
		function walk(e:Expr):Void {
			if (found || e == null) {
				return;
			}
			switch e.expr {
				case EConst(CIdent(n)) if (n == name): found = true;
				case _: ExprTools.iter(e, walk);
			}
		}
		walk(e);
		return found;
	}

	/** `ExpressionConverter.Unwrap`, and a cast, which a typed body reads back with. */
	static function Strip(e:Expr):Expr {
		return switch e.expr {
			case ECast(inner, _): Strip(inner);
			case EParenthesis(inner) | EMeta(_, inner) | ECheckType(inner, _): Strip(inner);
			case EReturn(inner) if (inner != null): Strip(inner);
			case EBlock([inner]): Strip(inner);
			case _: e;
		}
	}
	#end
}
