package codequery.sqlexpressions;

import haxe.macro.Expr;
#if macro
import haxe.macro.Context;
import haxe.macro.Printer;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
#end

/**
	The Haxe stand-in for C#'s `Expression<SqlCondition<T1>>`.

	C# reifies the lambda into an `Expression` tree at runtime and converts it there. Haxe has no
	runtime expression trees, so the conversion happens during compilation: the lambda never becomes
	a closure, it becomes the code that builds the `ISqlExpression` tree the statement carries.

	A column resolves to a static member of the entity's generated columns type (see
	`ColumnsBuilder`), so what a predicate compiles to is a reference and not a column built afresh
	on each call. Nothing in it depends on the statement it lands in, so the whole condition is built
	where it is written — there is no closure.
**/
class ExpressionConverter {
	#if macro
	/**
		Convert a predicate lambda into an expression building its `ISqlExpression`.

		`entity` is the row type the lambda's parameter stands for; the predicate is typed against
		it so that an editor can see inside the lambda and so the body is type-checked.
	**/
	public static function Convert(predicate:Expr, rows:Array<Type>):Expr {
		return ConvertLambda(predicate, rows, macro :Bool, "a predicate, e.g. a -> a.id == 12");
	}

	/**
		Convert a key selector — `a -> a.id`, the `SqlKeySelector` of the C# API — into an
		expression building its `ISqlExpression`. Any expression will do, not only a column.
	**/
	public static function ConvertKey(selector:Expr, rows:Array<Type>):Expr {
		// The key is whatever the expression is; only the rows being typed matter here.
		return ConvertLambda(selector, rows, macro :Dynamic, "a key selector, e.g. a -> a.id");
	}

	static function ConvertLambda(given:Expr, rows:Array<Type>, returns:ComplexType, expected:String):Expr {
		final lambda = ResolveLambda(given);
		TypeLambda(lambda, rows, returns);

		final fn = switch lambda.expr {
			case EFunction(_, f): f;
			case _: Context.error('Expected $expected', lambda.pos);
		}
		if (fn.args.length != rows.length) {
			Context.error('Expected $expected, taking ${rows.length} parameter${rows.length == 1 ? "" : "s"}',
				lambda.pos);
		}

		// Each parameter names a row, in the order the statement's sources are bound.
		final bound = new Map<String, Int>();
		for (index => arg in fn.args) {
			bound.set(arg.name, index);
		}
		return ToSqlExpression(fn.expr, bound, rows);
	}

	/**
		Type the lambda against the row it is written over and throw the result away.

		Nothing else types it — the tree is read as syntax — and Haxe answers completion, hover and
		go-to-definition while *typing* an expression. Without this an editor has nothing to offer
		inside the lambda. The typed expression is discarded, so none of it reaches the output.
	**/
	static function TypeLambda(lambda:Expr, rows:Array<Type>, returns:ComplexType):Void {
		final signature = ComplexType.TFunction([for (row in rows) row.toComplexType()], returns);
		Context.typeExpr(macro @:pos(lambda.pos) ($lambda : $signature));
	}

	/**
		The lambda an argument stands for.

		Usually it is written where it is used. It may instead name a function that answers with one
		— which is how an entity declares a join it is always made by, as C#'s `Booking.WithUnit`
		does: the function is read back and its lambda used as if it had been written out.
	**/
	static function ResolveLambda(e:Expr):Expr {
		final e = Unwrap(e);
		if (e.expr.match(EFunction(_, _))) {
			return e;
		}

		final declared = try Context.typeExpr(e) catch (_:Dynamic) return e;
		final field = switch declared.expr {
			case TField(_, FStatic(_, cf)): cf.get();
			case _: return e;
		}

		final body = field.expr();
		if (body == null) {
			return e;
		}
		// The function answers with the lambda, so what is wanted is what it returns.
		return switch Unwrap(Context.getTypedExpr(body)).expr {
			case EFunction(_, {expr: answered}): Returned(Unwrap(answered));
			case _: e;
		}
	}

	/** The expression a body answers with. */
	static function Returned(e:Expr):Expr {
		return switch e.expr {
			case EReturn(inner) if (inner != null): Unwrap(inner);
			case EBlock(exprs) if (exprs.length > 0): Returned(Unwrap(exprs[exprs.length - 1]));
			case _: e;
		}
	}

	/** Strip the syntax that carries no meaning for the conversion. */
	static function Unwrap(e:Expr):Expr {
		return switch e.expr {
			case EReturn(inner) if (inner != null): Unwrap(inner);
			case EParenthesis(inner): Unwrap(inner);
			// A cast's target type is named by annotating it, which is not part of the expression.
			case ECheckType(inner, _): Unwrap(inner);
			case EMeta(_, inner): Unwrap(inner);
			case EBlock([inner]): Unwrap(inner);
			case _: e;
		}
	}

	/** Haxe syntax in, an expression that builds the SQL tree out. */
	static function ToSqlExpression(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final e = Unwrap(e);
		return switch e.expr {
			case EBinop(op, left, right):
				final quantified = Quantified(op, left, right, bound, rows, e.pos);
				if (quantified != null) {
					return quantified;
				}
				final factory = FactoryFor(op, e.pos);
				final l = ToSqlExpression(left, bound, rows);
				final r = ToSqlExpression(right, bound, rows);
				macro $factory($l, $r);

			// Haxe says CASE WHEN with a ternary, so that is what it converts to.
			case ETernary(condition, then, otherwise) | EIf(condition, then, otherwise) if (otherwise != null):
				final branch = macro codequery.sqlexpressions.Expr.branch(
					${ToSqlExpression(condition, bound, rows)}, ${ToSqlExpression(then, bound, rows)});
				final fallback = ToSqlExpression(otherwise, bound, rows);
				macro codequery.sqlexpressions.Expr.caseWhen([$branch], $fallback);

			case EUnop(OpNot, false, operand):
				macro codequery.sqlexpressions.Expr.not(${ToSqlExpression(operand, bound, rows)});

			// The calls of `Sql`, which is where what SQL has and Haxe has not is written.
			case ECall({expr: EField({expr: EConst(CIdent("Sql"))}, name, _)}, args)
				| ECall({expr: EField({expr: EField({expr: EConst(CIdent("codequery"))}, "Sql", _)}, name, _)}, args):
				SqlCall(name, args, bound, rows, e.pos);

			case EField(_, _, _):
				final reached = PathOf(e, bound);
				if (reached == null) {
					// Not a column, so the only thing it can be is something with a value already —
					// an enum abstract's member, most often.
					final constant = ConstantOf(e);
					if (constant != null) {
						return constant;
					}
					Context.error('Only a column of a row this lambda is written over, or a constant, can be used here',
						e.pos);
				}
				ColumnFor(rows[reached.row], reached.row, reached.path, e.pos);

			case EConst(CInt(v, _)):
				macro ${Factory("constInt")}($v{Std.parseInt(v)});

			case EConst(CFloat(v, _)):
				macro ${Factory("constFloat")}($v{Std.parseFloat(v)});

			case EConst(CString(s, _)):
				macro ${Factory("constString")}($v{s});

			case EConst(CIdent("true")):
				macro ${Factory("constBool")}(true);

			case EConst(CIdent("false")):
				macro ${Factory("constBool")}(false);

			case EConst(CIdent("null")):
				macro ${Factory("constNull")}();

			// A negative literal is unary minus over a positive one, not a constant of its own.
			case EUnop(OpNeg, false, {expr: EConst(CInt(v, _))}):
				macro ${Factory("constInt")}($v{-Std.parseInt(v)});

			case _:
				// Already an expression — a lateral's inner query is handed the outer row's
				// columns this way, since it has no parameter of its own for them.
				if (IsSqlExpression(e)) {
					return e;
				}
				final constant = ConstantOf(e);
				if (constant != null) {
					return constant;
				}
				Context.error('Cannot convert to SQL: ${e.toString()}', e.pos);
		}
	}

	/**
		The constant an expression already is, or null where it is not one.

		`BookingStatus.Confirmed` is the case this is for: an enum abstract's member is its value by
		the time it is typed, so asking the compiler what it is costs nothing and means SQL sees the
		number the database stores rather than a name it would not know.
	**/
	static function ConstantOf(e:Expr):Null<Expr> {
		final typed = try Context.typeExpr(e) catch (_:Dynamic) return null;
		return switch UnwrapTyped(typed).expr {
			case TConst(TInt(v)): macro ${Factory("constInt")}($v{v});
			case TConst(TFloat(v)): macro ${Factory("constFloat")}($v{Std.parseFloat(v)});
			case TConst(TString(v)): macro ${Factory("constString")}($v{v});
			case TConst(TBool(v)): macro ${Factory("constBool")}($v{v});
			case TConst(TNull): macro ${Factory("constNull")}();
			case _: null;
		}
	}

	/** Whether an expression is already one of ours, and so needs no converting. */
	static function IsSqlExpression(e:Expr):Bool {
		return try {
			Context.unify(Context.typeof(e), Context.getType("codequery.sqlexpressions.ISqlExpression"));
		} catch (_:Dynamic) {
			false;
		}
	}

	/**
		A lateral join: the inner query is written against the outer row, and joined to it.

		Everything else takes a lambda over rows and converts it. A lateral takes a lambda that
		answers with a whole query, and that query is built by its own macro calls — which bind
		their parameters from zero in their own statement, knowing nothing of the row outside. So
		the outer row's columns are substituted into the body before any of that runs, each one
		marked as belonging a statement further out.
	**/
	public static function Lateral(self:Expr, lateral:Expr, joinType:String):Expr {
		final rows = EntitiesOf(self);
		final fn = switch lateral.expr {
			case EFunction(_, f) if (f.args.length == rows.length): f;
			case _: Context.error('Expected a lambda of ${rows.length} row(s) answering with a query',
					lateral.pos);
		}

		final bound = new Map<String, Int>();
		for (index => arg in fn.args) {
			bound.set(arg.name, index);
		}

		// Substituted before anything is typed: typing the body expands the inner query's own
		// macros, and they must see the outer row's columns already put in.
		final inner = SubstituteOuter(Unwrap(fn.expr), bound, rows);

		final kind = macro $p{["codequery", "sqlexpressions", "JoinType", joinType]};
		final query = macro(cast $self : codequery.queries.SelectQueryImpl);
		final joined = macro $query.JoinQuery($kind, (cast $inner : codequery.queries.SelectQueryImpl));

		// The joined query brings a row, as any other join does.
		return Answering(joined, rows.concat([LateralRow(inner, lateral.pos)]));
	}

	/** The row a lateral's query answers with. */
	static function LateralRow(inner:Expr, pos:Position):Type {
		return switch Context.typeof(inner).follow() {
			case TAbstract(_, [row]): row;
			case TInst(_, [row]): row;
			case t: Context.error('A lateral answers with a query; this one answers with ${t.toString()}', pos);
		}
	}

	/** Replace every reach into an outer row with that column, marked a statement further out. */
	static function SubstituteOuter(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		return switch e.expr {
			case EField(_, _, _):
				final reached = PathOf(e, bound);
				if (reached == null) {
					{expr: ExprTools.map(e, inner -> SubstituteOuter(inner, bound, rows)).expr, pos: e.pos};
				} else {
					final row = rows[reached.row];
					final column = ColumnFor(row, reached.row, reached.path, e.pos);
					// Annotated with what the member holds, so the inner query still type-checks —
					// a predicate is typed before it is read, and a column is not an Int.
					final held = MemberTypeOf(reached.path, row, e.pos).toComplexType();
					macro(cast codequery.sqlexpressions.Expr.outer($column) : $held);
				}

			case _:
				ExprTools.map(e, inner -> SubstituteOuter(inner, bound, rows));
		}
	}

	/** An enum abstract's member arrives wrapped in the cast to its underlying type. */
	static function UnwrapTyped(e:TypedExpr):TypedExpr {
		return switch e.expr {
			case TCast(inner, _): UnwrapTyped(inner);
			case TMeta(_, inner): UnwrapTyped(inner);
			case TParenthesis(inner): UnwrapTyped(inner);
			case _: e;
		}
	}

	/**
		`x > ANY (…)` and `x = ALL (…)`, which read as a comparison against `Sql.any` or `Sql.all` —
		so the operator belongs to the comparison and the quantifier to the side it is against.
	**/
	static function Quantified(op:Binop, left:Expr, right:Expr, bound:Map<String, Int>, rows:Array<Type>,
			pos:Position):Null<Expr> {
		final quantifier = switch Unwrap(right).expr {
			case ECall({expr: EField({expr: EConst(CIdent("Sql"))}, name, _)}, [query]) if (name == "any" || name == "all"):
				{name: name == "any" ? "Any" : "All", query: query};
			case _: null;
		}
		if (quantifier == null) {
			return null;
		}

		final comparison = OperatorFor(op, pos);
		final name = quantifier.name;
		final subquery = Statement(quantifier.query);
		return macro codequery.sqlexpressions.Expr.quantified(${ToSqlExpression(left, bound, rows)}, $comparison,
			$p{["codequery", "sqlexpressions", "Quantifier", name]}, $subquery);
	}

	/** The `SqlBinaryOperator` an operator maps to, which a quantified comparison needs by name. */
	static function OperatorFor(op:Binop, pos:Position):Expr {
		final name = switch op {
			case OpEq: "Equal";
			case OpNotEq: "NotEqual";
			case OpLt: "LessThan";
			case OpLte: "LessThanOrEqual";
			case OpGt: "GreaterThan";
			case OpGte: "GreaterThanOrEqual";
			case _: Context.error('Operator ${new Printer().printBinop(op)} cannot be quantified', pos);
		}
		return macro $p{["codequery", "sqlexpressions", "SqlBinaryOperator", name]};
	}

	/** One of `Sql`'s calls, as the expression it stands for. */
	static function SqlCall(name:String, args:Array<Expr>, bound:Map<String, Int>, rows:Array<Type>, pos:Position):Expr {
		// Converted only where a call actually wants it: `isIn` takes its values as a list, which is
		// not an expression and would not convert.
		final arg = (index:Int) -> ToSqlExpression(args[index], bound, rows);
		final list = (from:Int) -> {
			expr: EArrayDecl([for (index in from...args.length) arg(index)]),
			pos: pos
		};

		return switch name {
			case "isIn" | "notIn":
				final values = switch Unwrap(args[1]).expr {
					case EArrayDecl(items): {expr: EArrayDecl([for (item in items) ToSqlExpression(item, bound, rows)]),
							pos: pos};
					case _: Context.error("Sql." + name + " takes the values as a list written out here", args[1].pos);
				}
				final negate = name == "notIn";
				macro codequery.sqlexpressions.Expr.isIn(${arg(0)}, $values, $v{negate});

			case "inQuery" | "notInQuery":
				final negate = name == "notInQuery";
				final subquery = macro(cast ${args[1]} : codequery.queries.SelectQueryImpl).ToExpression();
				macro codequery.sqlexpressions.Expr.inQuery(${arg(0)}, $subquery, $v{negate});

			case "between" | "notBetween":
				final negate = name == "notBetween";
				macro codequery.sqlexpressions.Expr.between(${arg(0)}, ${arg(1)}, ${arg(2)}, $v{negate});

			case "like" | "notLike" | "ilike" | "notIlike":
				final matching = StringTools.endsWith(name.toLowerCase(), "ilike") ? "ILIKE" : "LIKE";
				final comparison = macro codequery.sqlexpressions.Expr.infix($v{matching}, ${list(0)});
				StringTools.startsWith(name, "not") ? macro codequery.sqlexpressions.Expr.not($comparison) : comparison;

			case "isDistinctFrom" | "isNotDistinctFrom":
				final negate = name == "isNotDistinctFrom";
				macro codequery.sqlexpressions.Expr.isDistinctFrom(${arg(0)}, ${arg(1)}, $v{negate});

			case "castTo":
				macro codequery.sqlexpressions.Expr.castTo(${arg(0)}, ${args[1]});

			case "raw":
				macro codequery.sqlexpressions.Expr.raw(${args[0]});

			case "param":
				Parameterised(args[0]);

			case "scalar" | "correlated":
				final correlated = name == "correlated";
				macro codequery.sqlexpressions.Expr.scalar(${Statement(args[0])}, $v{correlated});

			// `any` and `all` stand on one side of a comparison, so the operator is picked up there.
			case "any" | "all":
				Context.error('Sql.$name belongs on one side of a comparison, e.g. a.id == Sql.any(q)', pos);

			// EXTRACT takes one argument written as `part FROM value`, not two.
			case "datePart":
				macro codequery.sqlexpressions.Expr.call("EXTRACT", [
					codequery.sqlexpressions.Expr.infix("FROM", [codequery.sqlexpressions.Expr.raw(${args[0]}), ${arg(1)}])
				]);

			case "dateAdd" | "dateSubtract":
				final sign = name == "dateAdd" ? "+" : "-";
				macro codequery.sqlexpressions.Expr.infix($v{sign}, [${arg(0)}, ${Interval(args[1], args[2])}]);

			case "abs": macro codequery.sqlexpressions.Expr.call("ABS", ${list(0)});
			case "round": macro codequery.sqlexpressions.Expr.call("ROUND", ${list(0)});
			case "ceil": macro codequery.sqlexpressions.Expr.call("CEIL", ${list(0)});
			case "floor": macro codequery.sqlexpressions.Expr.call("FLOOR", ${list(0)});
			case "sign": macro codequery.sqlexpressions.Expr.call("SIGN", ${list(0)});
			case "power": macro codequery.sqlexpressions.Expr.call("POWER", ${list(0)});
			case "sqrt": macro codequery.sqlexpressions.Expr.call("SQRT", ${list(0)});
			case "exp": macro codequery.sqlexpressions.Expr.call("EXP", ${list(0)});
			case "ln": macro codequery.sqlexpressions.Expr.call("LN", ${list(0)});
			case "log": macro codequery.sqlexpressions.Expr.call("LOG", ${list(0)});
			case "greatest": macro codequery.sqlexpressions.Expr.call("GREATEST", ${list(0)});
			case "least": macro codequery.sqlexpressions.Expr.call("LEAST", ${list(0)});
			case "left": macro codequery.sqlexpressions.Expr.call("LEFT", ${list(0)});
			case "right": macro codequery.sqlexpressions.Expr.call("RIGHT", ${list(0)});
			case "random": macro codequery.sqlexpressions.Expr.call("RANDOM", ${list(0)});
			case "now": macro codequery.sqlexpressions.Expr.call("NOW", ${list(0)});

			case "coalesce": macro codequery.sqlexpressions.Expr.call("COALESCE", ${list(0)});
			case "nullIf": macro codequery.sqlexpressions.Expr.call("NULLIF", ${list(0)});
			case "upper": macro codequery.sqlexpressions.Expr.call("UPPER", ${list(0)});
			case "lower": macro codequery.sqlexpressions.Expr.call("LOWER", ${list(0)});
			case "length": macro codequery.sqlexpressions.Expr.call("LENGTH", ${list(0)});
			case "trim": macro codequery.sqlexpressions.Expr.call("TRIM", ${list(0)});
			case "substring": macro codequery.sqlexpressions.Expr.call("SUBSTRING", ${list(0)});
			case "concat": macro codequery.sqlexpressions.Expr.infix("||", ${list(0)});

			case _: Context.error('Sql.$name has no SQL here yet', pos);
		}
	}

	/** The statement behind a query handed to `Sql`. */
	static function Statement(query:Expr):Expr {
		return macro(cast $query : codequery.queries.SelectQueryImpl).ToExpression();
	}

	/** `INTERVAL 'n unit'`, which is a literal of its own rather than a function of two values. */
	static function Interval(count:Expr, unit:Expr):Expr {
		return macro codequery.sqlexpressions.Expr.raw("INTERVAL \'" + $count + " " + $unit + "\'");
	}

	/** The same value as `Valued`, but sent beside the statement rather than written into it. */
	static function Parameterised(value:Expr):Expr {
		return ParameterisedAs(value, Context.typeof(value));
	}

	/** The same, where the type is known and the expression cannot be typed on its own. */
	public static function ParameterisedAs(value:Expr, type:Type):Expr {
		final factory = Factory(switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int"}, _): "paramInt";
			case TAbstract(_.get() => {name: "Float"}, _): "paramFloat";
			case TAbstract(_.get() => {name: "Bool"}, _): "paramBool";
			case TInst(_.get() => {name: "String"}, _): "paramString";
			case TInst(_.get() => {name: "Date"}, _): "paramDate";
			case t: Context.error('${t.toString()} is not something a parameter can hold', value.pos);
		});
		return macro $factory($value);
	}

	static function FactoryFor(op:Binop, pos:Position):Expr {
		return Factory(switch op {
			case OpEq: "equal";
			case OpNotEq: "notEqual";
			case OpLt: "lessThan";
			case OpLte: "lessThanOrEqual";
			case OpGt: "greaterThan";
			case OpGte: "greaterThanOrEqual";
			case OpBoolAnd: "and";
			case OpBoolOr: "or";
			case OpAdd: "add";
			case OpSub: "subtract";
			case OpMult: "multiply";
			case OpDiv: "divide";
			case OpMod: "modulo";
			case _: Context.error('Operator ${new Printer().printBinop(op)} has no SQL equivalent', pos);
		});
	}

	/** One of `Expr`'s factory methods, which is what a converted expression is built out of. */
	static function Factory(name:String):Expr {
		return macro $p{["codequery", "sqlexpressions", "Expr", name]};
	}

	/**
		The row a field access reaches, and the path of members to it — `b.price.zar` is row `b` and
		the path `[price, zar]`. Null where it does not start at a row this lambda is written over.
	**/
	static function PathOf(e:Expr, bound:Map<String, Int>):Null<{row:Int, path:Array<String>}> {
		final path:Array<String> = [];
		var walk = Unwrap(e);
		while (true) {
			switch walk.expr {
				case EField(owner, field, _):
					path.unshift(field);
					walk = Unwrap(owner);
				case EConst(CIdent(name)) if (bound.exists(name)):
					return {row: bound[name], path: path};
				case _:
					return null;
			}
		}
	}

	/**
		How a column of `row` is reached, by the path of members named to get to it.

		An entity's columns come from its generated statics, which carry the names its metadata
		settles. A projection answers with an anonymous structure — no name, no package, no
		metadata — so there is nothing to generate statics from and nothing they would say: a
		member of one is a column of that name, built where it is used.
	**/
	static function ColumnFor(row:Type, index:Int, path:Array<String>, pos:Position):Expr {
		final name = MemberOf(path, row, pos);
		if (!IsStructure(row)) {
			return ColumnsBuilder.Member(ColumnsBuilder.Of(row, index), name);
		}
		return macro new codequery.sqlexpressions.ColumnSqlExpression(
			codequery.sqlexpressions.ParameterSqlSource.At($v{index}), $v{name});
	}

	/** Whether a row is an anonymous structure — what a projection answers with. */
	static function IsStructure(row:Type):Bool {
		return row.follow().match(TAnonymous(_));
	}

	/** The fields a row has, whether it is a class or a structure. */
	static function FieldsOf(row:Type):Null<Array<ClassField>> {
		return switch row.follow() {
			case TInst(t, _): t.get().fields.get();
			case TAnonymous(a): a.get().fields;
			case _: null;
		}
	}

	/**
		Checks that the row really has this path, so that a typo is a compile error here rather than
		a confusing one further on. Answers with the name the column is known by, which for a nested
		member is the path to it.
	**/
	static function MemberOf(path:Array<String>, entity:Type, pos:Position):String {
		var row = entity;
		for (step in 0...path.length) {
			final found = FieldNamed(row, path[step]);
			if (found == null) {
				final reached = step == 0
					? row.toString()
					: '${row.toString()} (reached by ${path.slice(0, step).join(".")})';
				Context.error('$reached has no field "${path[step]}"', pos);
			}
			if (step == path.length - 1) {
				break;
			}
			row = found.type;
		}

		return path.join(ColumnsBuilder.Separator);
	}

	/** What the member at the end of a path holds. */
	static function MemberTypeOf(path:Array<String>, entity:Type, pos:Position):Type {
		var row = entity;
		var held:Null<Type> = null;
		for (step in 0...path.length) {
			final found = FieldNamed(row, path[step]);
			if (found == null) {
				Context.error('${row.toString()} has no field "${path[step]}"', pos);
			}
			held = found.type;
			row = found.type;
		}
		return held;
	}

	static function FieldNamed(row:Type, name:String):Null<ClassField> {
		final fields = FieldsOf(row);
		if (fields == null) {
			return null;
		}
		for (field in fields) {
			if (field.name == name) {
				return field;
			}
		}
		return null;
	}

	/**
		Convert a projection lambda — `a -> {store: a.fromStoreId, note: a.noteNo}`, the
		`SqlProjection` of the C# API — into the selection it describes and the row type it leaves.

		A lambda naming a row rather than building a structure — `(a, b) -> b`, which is what
		`Reduce` is for — selects that row's columns and keeps its type.
	**/
	public static function ConvertProjection(projection:Expr, rows:Array<Type>):{selection:Expr, row:Type} {
		final fn = switch projection.expr {
			case EFunction(_, f): f;
			case _: Context.error("Expected a projection, e.g. a -> {note: a.noteNo}", projection.pos);
		}
		if (fn.args.length != rows.length) {
			Context.error('Expected a projection taking ${rows.length} parameter${rows.length == 1 ? "" : "s"}',
				projection.pos);
		}

		final bound = new Map<String, Int>();
		for (index => arg in fn.args) {
			bound.set(arg.name, index);
		}

		// Typed first, and deliberately: the walk below only reads syntax, so if it ran first an
		// editor would get nothing back from inside the projection. Typing is what answers that.
		final row = ProjectedRow(fn, rows, projection.pos);
		return {selection: ToProjection(Unwrap(fn.expr), bound, rows), row: row};
	}

	/**
		The type a projection answers with, taken from the lambda itself: give its parameters the
		row types and the compiler works out the rest, which is also what lets an editor see inside.
	**/
	static function ProjectedRow(fn:Function, rows:Array<Type>, pos:Position):Type {
		final args:Array<FunctionArg> = [
			for (index => arg in fn.args) {name: arg.name, type: rows[index].toComplexType()}
		];
		final typed = {expr: EFunction(FAnonymous, {args: args, ret: null, expr: fn.expr}), pos: pos};
		return switch Context.typeof(typed).follow() {
			case TFun(_, ret): ret;
			case t: Context.error('A projection must answer with something; this one is ${t.toString()}', pos);
		}
	}

	static function ToProjection(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		return switch e.expr {
			// A structure names each member; the names are what the columns come back as.
			case EObjectDecl(fields):
				final members = {
					expr: EArrayDecl([
						for (field in fields) {
							final value = ToSqlExpression(field.expr, bound, rows);
							macro new codequery.sqlexpressions.ProjectionMember($v{field.field}, $value);
						}
					]),
					pos: e.pos
				};
				macro new codequery.sqlexpressions.ProjectionSqlExpression($members);

			// A row on its own selects that row's columns.
			case EConst(CIdent(name)) if (bound.exists(name)):
				final index = bound[name];
				final source = IsStructure(rows[index])
					? macro codequery.sqlexpressions.ParameterSqlSource.At($v{index})
					: ColumnsBuilder.Member(ColumnsBuilder.Of(rows[index], index), "Source");
				macro new codequery.sqlexpressions.AllColumnsSqlExpression($source);

			// One expression, naming nothing — `a -> a.name`, which C# answers with a query of that
			// value. There is one column and it needs no name, since nothing reads it by one.
			case _:
				final only = ToSqlExpression(e, bound, rows);
				macro new codequery.sqlexpressions.ProjectionSqlExpression(
					[new codequery.sqlexpressions.ProjectionMember("", $only)]);
		}
	}

	/**
		Convert an aggregate projection — `a -> {rows: a.count(), biggest: a.max(r -> r.quantity)}`.

		The lambda's first parameter is the set of aggregates over the query's rows; a window the
		query has defined arrives as a further parameter, and an aggregate reads over it with
		`.over(w)`.
	**/
	public static function ConvertAggregation(projection:Expr, rows:Array<Type>, query:Expr):{selection:Expr, row:Type} {
		final fn = switch projection.expr {
			case EFunction(_, f): f;
			case _: Context.error("Expected an aggregate projection, e.g. a -> {rows: a.count()}", projection.pos);
		}

		// The aggregates stand in for the rows themselves, so the parameters are the set, then one
		// per window the query has picked up.
		final windows = rows.length - 1;
		if (fn.args.length != 1 + windows) {
			Context.error('Expected an aggregate projection taking ${1 + windows} parameter${windows == 0 ? "" : "s"}',
				projection.pos);
		}

		TypeAggregation(fn, rows, projection.pos);

		final bound = new Map<String, Int>();
		bound.set(fn.args[0].name, 0);
		final named = [for (index in 0...windows) fn.args[index + 1].name => index + 1];

		final members = switch Unwrap(fn.expr).expr {
			case EObjectDecl(fields): fields;
			case e: Context.error('An aggregate projection is a structure, not ${Unwrap(fn.expr).toString()}',
					projection.pos);
		}

		final built = {
			expr: EArrayDecl([
				for (field in members) {
					final value = ToAggregate(field.expr, fn.args[0].name, named, rows, query);
					macro new codequery.sqlexpressions.ProjectionMember($v{field.field}, $value);
				}
			]),
			pos: projection.pos
		};

		return {
			selection: macro new codequery.sqlexpressions.ProjectionSqlExpression($built),
			row: ProjectedRow(fn, AggregationRows(rows), projection.pos)
		};
	}

	/** The parameter types an aggregate projection is typed against. */
	static function AggregationRows(rows:Array<Type>):Array<Type> {
		final set = Context.getType("codequery.IAggregateSet");
		final window = Context.getType("codequery.INamedWindow");
		final typed = [switch set {
			case TInst(t, _): TInst(t, [rows[0]]);
			case t: t;
		}];
		for (_ in 1...rows.length) {
			typed.push(window);
		}
		return typed;
	}

	static function TypeAggregation(fn:Function, rows:Array<Type>, pos:Position):Void {
		final signature = ComplexType.TFunction([for (row in AggregationRows(rows)) row.toComplexType()], macro :Dynamic);
		final lambda = {expr: EFunction(FAnonymous, fn), pos: pos};
		Context.typeExpr(macro @:pos(pos) ($lambda : $signature));
	}

	/** One member of an aggregate projection: a call on the aggregate set, perhaps over a window. */
	static function ToAggregate(e:Expr, set:String, windows:Map<String, Int>, rows:Array<Type>, query:Expr):Expr {
		final e = Unwrap(e);
		return switch e.expr {
			// `<aggregate>.over(w)`
			case ECall({expr: EField({expr: inner}, "over", _)}, [window]):
				final named = switch Unwrap(window).expr {
					case EConst(CIdent(name)) if (windows.exists(name)): windows[name];
					case _: Context.error("over() takes a window this query has defined", window.pos);
				}
				final aggregate = ToAggregate({expr: inner, pos: e.pos}, set, windows, rows, query);
				macro $aggregate.OverWindow(${WindowAt(query, named)});

			// `<aggregate>.overRows(w -> …)` — a window written out rather than named.
			case ECall({expr: EField({expr: inner}, "overRows", _)}, [spec]):
				final window = ConvertWindow(spec, [rows[0]]);
				final partitionBy = window.partitionBy;
				final orderBy = window.orderBy;
				final frame = window.frame;
				final aggregate = ToAggregate({expr: inner, pos: e.pos}, set, windows, rows, query);
				macro $aggregate.OverDefinition(
					new codequery.sqlexpressions.WindowDefinition($partitionBy, $orderBy, $frame));

			// `<aggregate>.filter(r -> …)`
			case ECall({expr: EField({expr: inner}, "filter", _)}, [predicate]):
				final condition = Convert(predicate, [rows[0]]);
				final aggregate = ToAggregate({expr: inner, pos: e.pos}, set, windows, rows, query);
				macro $aggregate.Filtered($condition);

			// `<aggregate>.distinct()`
			case ECall({expr: EField({expr: inner}, "distinct", _)}, []):
				final aggregate = ToAggregate({expr: inner, pos: e.pos}, set, windows, rows, query);
				macro $aggregate.Distinctly();



			case ECall({expr: EField({expr: EConst(CIdent(name))}, fn, _)}, args) if (name == set):
				Aggregate(fn, args, rows, e.pos);

			case _:
				Context.error('An aggregate projection selects aggregates, not ${e.toString()}', e.pos);
		}
	}

	static function Aggregate(fn:String, args:Array<Expr>, rows:Array<Type>, pos:Position):Expr {
		final row = [rows[0]];

		// The window functions are not aggregates and have a node of their own.
		final windowed = WindowFunctionNamed(fn);
		if (windowed != null) {
			final arguments = {
				expr: EArrayDecl(args.length == 0 ? [] : [ConvertKey(args[0], row)].concat(
					args.length > 1 ? [ToSqlExpression(args[1], new Map(), rows)] : [])),
				pos: pos
			};
			return macro new codequery.sqlexpressions.WindowFunctionExpression(
				$p{["codequery", "sqlexpressions", "WindowFunction", windowed]}, $arguments);
		}

		final kind = macro $p{["codequery", "sqlexpressions", "AggregateType", AggregateNamed(fn, pos)]};
		if (fn == "count") {
			return macro new codequery.sqlexpressions.AggregateSqlExpression($kind);
		}
		final argument = ConvertKey(args[0], row);
		final distinct = fn == "countDistinct";
		return macro new codequery.sqlexpressions.AggregateSqlExpression($kind, $argument, $v{distinct});
	}

	static function WindowFunctionNamed(fn:String):Null<String> {
		return switch fn {
			case "rowNumber": "RowNumber";
			case "rank": "Rank";
			case "denseRank": "DenseRank";
			case "lead": "Lead";
			case "lag": "Lag";
			case "firstValue": "FirstValue";
			case "lastValue": "LastValue";
			case _: null;
		}
	}

	static function AggregateNamed(fn:String, pos:Position):String {
		return switch fn {
			case "count" | "countDistinct": "Count";
			case "sum": "Sum";
			case "avg": "Avg";
			case "min": "Min";
			case "max": "Max";
			case _: Context.error('$fn is not an aggregate', pos);
		}
	}

	/** The window a statement holds at `index` among its sources, read back when the query runs. */
	static function WindowAt(query:Expr, index:Int):Expr {
		return macro codequery.queries.SelectQueryImpl.WindowOf($query, $v{index});
	}

	/**
		Convert a window spec — `w -> w.PartitionBy(a -> a.deliveryId).OrderBy(a -> a.id)` — into
		the partition keys and ordering terms it describes. The statement names it; a name is not
		something the spec carries.
	**/
	public static function ConvertWindow(spec:Expr, rows:Array<Type>):{partitionBy:Expr, orderBy:Expr, frame:Expr} {
		final fn = switch spec.expr {
			case EFunction(_, f) if (f.args.length == 1): f;
			case _: Context.error("Expected a window spec, e.g. w -> w.PartitionBy(a -> a.id)", spec.pos);
		}

		final partitionBy:Array<Expr> = [];
		final orderBy:Array<Expr> = [];
		final frame:Array<Expr> = [];
		WalkWindow(Unwrap(fn.expr), fn.args[0].name, rows, partitionBy, orderBy, frame);

		return {
			partitionBy: {expr: EArrayDecl(partitionBy), pos: spec.pos},
			orderBy: {expr: EArrayDecl(orderBy), pos: spec.pos},
			frame: frame.length == 0 ? macro null : frame[0]
		};
	}

	/** The chain is read from the outside in, so the terms are collected in the order written. */
	static function WalkWindow(e:Expr, spec:String, rows:Array<Type>, partitionBy:Array<Expr>, orderBy:Array<Expr>,
			frame:Array<Expr>):Void {
		switch Unwrap(e).expr {
			case EConst(CIdent(name)) if (name == spec):
				return;

			case ECall({expr: EField(owner, call, _)}, args):
				WalkWindow(owner, spec, rows, partitionBy, orderBy, frame);
				if (call == "Rows" || call == "Range") {
					final kind = macro $p{["codequery", "sqlexpressions", "FrameKind", call]};
					frame.push(macro new codequery.sqlexpressions.WindowFrame($kind, ${args[0]}, ${args[1]}));
					return;
				}
				final key = ConvertKey(args[0], rows);
				switch call {
					case "PartitionBy":
						partitionBy.push(key);
					case "OrderBy" | "OrderByDesc":
						final ascending = call == "OrderBy";
						final nulls = args.length > 1
							? args[1]
							: macro codequery.sqlexpressions.NullsOrdering.Default;
						orderBy.push(macro new codequery.sqlexpressions.OrderByExpression($key, $v{ascending}, $nulls));
					case _:
						Context.error('A window is partitioned, ordered and framed; $call is none of them', e.pos);
				}

			case _:
				Context.error('Expected a window spec built on "$spec", not ${e.toString()}', e.pos);
		}
	}

	/**
		The column a `Set` is assigning to — a lambda naming one member of the row, and nothing else,
		since that is the only thing SQL can assign to.
	**/
	public static function ConvertColumn(selector:Expr, rows:Array<Type>):Expr {
		final converted = ConvertKey(selector, rows);
		return macro(${converted} : codequery.sqlexpressions.ColumnSqlExpression);
	}

	/**
		What a `Set` is assigning: a lambda is an expression over the row, and anything else is a
		value to be read where it stands.
	**/
	public static function ConvertValue(value:Expr, rows:Array<Type>):Expr {
		return switch value.expr {
			case EFunction(_, _): ConvertKey(value, rows);
			case _: Valued(value);
		}
	}

	/** A runtime value, as the constant it will be by the time the statement runs. */
	public static function Valued(value:Expr):Expr {
		return ValuedAs(value, Context.typeof(value));
	}

	/** The same, where the type is already known and the expression cannot be typed on its own. */
	public static function ValuedAs(value:Expr, type:Type):Expr {
		// Unwrapped first: an enum abstract is its underlying number by the time SQL sees it, and
		// SqlDate is a date.
		final factory = Factory(switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int"}, _): "constInt";
			case TAbstract(_.get() => {name: "Float"}, _): "constFloat";
			case TAbstract(_.get() => {name: "Bool"}, _): "constBool";
			case TInst(_.get() => {name: "String"}, _): "constString";
			case TInst(_.get() => {name: "Date"}, _): "constDate";
			case t: Context.error('${t.toString()} is not something a column can hold', value.pos);
		});
		return macro $factory($value);
	}

	/** The column names a conflict is judged on — one lambda, or a structure naming several. */
	public static function ConvertColumnNames(columns:Expr, rows:Array<Type>):Expr {
		final keys = ConvertKeySet(columns, rows);
		return macro codequery.sqlexpressions.ProjectionKeys.NamesOf($keys);
	}

	/** An insert answers with an insert, over the same row. */
	public static function AnsweringInsert(statement:Expr, self:Expr):Expr {
		final rows = EntitiesOf(self);
		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: "IInsertQuery",
			params: [TPType(rows[0].toComplexType())]
		});
		return macro(cast $statement : $queryType);
	}

	/** An update or a delete answers with a query of its own kind, over the same row. */
	public static function AnsweringMutation(statement:Expr, self:Expr):Expr {
		final kind = switch Context.typeof(self).follow() {
			case TAbstract(t, rows): {name: t.get().name, rows: rows};
			case t: Context.error('Not an update or a delete: ${t.toString()}', self.pos);
		}
		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: kind.name,
			params: [for (row in kind.rows) TPType(row.toComplexType())]
		});
		return macro(cast $statement : $queryType);
	}

	/**
		An INSERT of one entity: a column and a read of the matching member, for every column the
		row has, nested members included.
	**/
	public static function ConvertInsert(table:Expr, entry:Expr, entity:Type):Expr {
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', entry.pos);
		}

		final columns:Array<Expr> = [];
		final values:Array<Expr> = [];
		InsertMembers(row, entry, [], [], columns, values);

		final columnList = {expr: EArrayDecl(columns), pos: entry.pos};
		final valueList = {expr: EArrayDecl(values), pos: entry.pos};
		return macro codequery.queries.InsertStatement.Of($table, $columnList, $valueList);
	}

	/** `UPDATE … FROM` and `DELETE … USING`, which reach a second row. */
	public static function MutationFrom(table:Expr, source:Expr, begins:String, answers:String):Expr {
		final rows = [EntityOf(table), EntityOf(source)];
		final statement = macro(cast $source : codequery.queries.SelectQueryImpl).ToExpression();
		final begun = macro $p{["codequery", "queries", "MutationQueryImpl", begins]}($table.Table, $statement);

		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: answers,
			params: [for (row in rows) TPType(row.toComplexType())]
		});
		return macro(cast $begun : $queryType);
	}

	/** Several entities in one statement — the same columns, a row of values each. */
	public static function ConvertInsertMany(table:Expr, entries:Expr, entity:Type):Expr {
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', entries.pos);
		}

		// The columns are the same for every row, so they are read once, off a name standing for
		// whichever entity is being written.
		final columns:Array<Expr> = [];
		final values:Array<Expr> = [];
		InsertMembers(row, macro entry, [], [], columns, values);

		final columnList = {expr: EArrayDecl(columns), pos: entries.pos};
		final valueList = {expr: EArrayDecl(values), pos: entries.pos};
		return macro codequery.queries.InsertStatement.Many($table, $columnList,
			[for (entry in $entries) $valueList]);
	}

	/** `INSERT … SELECT`, where the rows come from a query. */
	public static function ConvertInsertFrom(table:Expr, source:Expr, entity:Type):Expr {
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', source.pos);
		}

		final columns:Array<Expr> = [];
		final values:Array<Expr> = [];
		InsertMembers(row, macro entry, [], [], columns, values);

		final columnList = {expr: EArrayDecl(columns), pos: source.pos};
		final statement = macro(cast $source : codequery.queries.SelectQueryImpl).ToExpression();
		return macro codequery.queries.InsertStatement.FromQuery($table, $columnList, $statement);
	}

	static function InsertMembers(row:ClassType, entry:Expr, member:Array<String>, visited:Array<String>,
			columns:Array<Expr>, values:Array<Expr>):Void {
		for (field in row.fields.get()) {
			if (!field.isPublic) {
				continue;
			}
			switch field.kind {
				case FVar(AccNormal | AccNo, _):
				case _: continue;
			}

			final name = field.name;
			final read = macro $entry.$name;
			final nested = switch field.type.follow() {
				case TInst(t, _):
					final held = t.get();
					final path = held.pack.concat([held.name]).join(".");
					(path == "String" || path == "Date") ? null : held;
				case _: null;
			}

			if (nested == null) {
				final column = member.concat([ColumnsBuilder.ColumnNameOf(field)]).join(ColumnsBuilder.Separator);
				columns.push(macro $v{column});
				// Sent beside the statement rather than written into it, which is the
				// strategy's default and the safer one.
				values.push(ParameterisedAs(read, field.type));
				continue;
			}

			final path = nested.pack.concat([nested.name]).join(".");
			if (visited.indexOf(path) >= 0) {
				Context.error('${row.name}.$name contains itself, so its columns have no end', entry.pos);
			}
			InsertMembers(nested, read, member.concat([ColumnsBuilder.ColumnNameOf(field)]),
				visited.concat([path]), columns, values);
		}
	}

	/** Whether an optional macro argument was left out at the call site. */
	public static function Omitted(arg:Null<Expr>):Bool {
		return arg == null || arg.expr.match(EConst(CIdent("null")));
	}

	/**
		A join: the source brings a row, the condition is written over every row the query then has,
		and which method is called depends on whether the source is a table or another query.
	**/
	public static function Join(self:Expr, source:Expr, on:Null<Expr>, joinType:String):Expr {
		final rows = EntitiesOf(self).concat([EntityOf(source)]);
		if (rows.length > MaxRows) {
			Context.error('A query can join up to $MaxRows rows, as in C#; this one would have ${rows.length}',
				source.pos);
		}

		final kind = macro $p{["codequery", "sqlexpressions", "JoinType", joinType]};
		final query = macro(cast $self : codequery.queries.SelectQueryImpl);
		final inner = macro(cast $source : codequery.queries.SelectQueryImpl);

		// A cross join has no condition, so it is left off rather than passed as null.
		final joined = if (on == null) {
			IsTable(source) ? macro $query.JoinTable($kind, $source) : macro $query.JoinQuery($kind, $inner);
		} else {
			final condition = Convert(on, rows);
			IsTable(source)
				? macro $query.JoinTable($kind, $source, $condition)
				: macro $query.JoinQuery($kind, $inner, $condition);
		}

		return Answering(joined, rows);
	}

	/** The row a window arrives as. */
	public static function WindowRow():Type {
		return Context.getType("codequery.INamedWindow");
	}

	/**
		One grouping set — a lambda naming one key, or a structure naming several:
		`r -> r.unitId`, or `r -> {a: r.unitId, b: r.guestId}`.
	**/
	public static function ConvertKeySet(set:Expr, rows:Array<Type>):Expr {
		final body = switch set.expr {
			case EFunction(_, f): Unwrap(f.expr);
			case _: Context.error("Expected a grouping set, e.g. r -> r.unitId", set.pos);
		}
		// One key is not a structure, so it is not a projection either.
		if (!body.expr.match(EObjectDecl(_))) {
			final key = ConvertKey(set, rows);
			return macro [$key];
		}
		final selection = ConvertProjection(set, rows).selection;
		return macro codequery.sqlexpressions.ProjectionKeys.Of($selection);
	}

	/** `UNION`, `INTERSECT` and `EXCEPT`, which put two statements' rows together. */
	public static function SetOperation(self:Expr, other:Expr, type:String):Expr {
		final rows = EntitiesOf(self);
		final kind = macro $p{["codequery", "sqlexpressions", "SetOperationType", type]};
		final right = macro(cast $other : codequery.queries.SelectQueryImpl);
		return Answering(macro(cast $self : codequery.queries.SelectQueryImpl).UnionWith($kind, $right), rows);
	}

	/** As many rows as C# has an `ISelectQuery` for. */
	public static final MaxRows = 8;

	/**
		Give a statement back the row types it is over.

		Building a statement needs no generics — `SelectQueryImpl` does all of it — so a clause
		answers with one of those, and this puts it back into the `ISelectQueryN` for however many
		rows the query now has. The cast is safe by construction: the arity is counted here.
	**/
	public static function Answering(query:Expr, rows:Array<Type>):Expr {
		final name = "ISelectQuery" + (rows.length == 1 ? "" : Std.string(rows.length));
		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: name,
			params: [for (row in rows) TPType(row.toComplexType())]
		});
		return macro(cast $query : $queryType);
	}

	/** Whether the thing being joined in is a table rather than another query. */
	static function IsTable(source:Expr):Bool {
		return switch Context.typeof(source).follow() {
			case TInst(t, _): HasInterface(t.get(), "IQuery");
			case TAbstract(_, _): false;
			case _: false;
		}
	}

	static function HasInterface(row:ClassType, name:String):Bool {
		if (row.name == name) {
			return true;
		}
		for (implemented in row.interfaces) {
			if (HasInterface(implemented.t.get(), name)) {
				return true;
			}
		}
		return row.superClass != null && HasInterface(row.superClass.t.get(), name);
	}



	/** The row types a query is over, read from the static type of the query itself. */
	public static function EntitiesOf(query:Expr):Array<Type> {
		return switch Context.typeof(query).follow() {
			case TAbstract(_, rows) if (rows.length > 0): rows;
			case TInst(_, rows) if (rows.length > 0): rows;
			case t: Context.error('Cannot tell what rows this query is over: ${t.toString()}', query.pos);
		}
	}

	/** The row type behind an `IQuery<T>` or `ISelectQuery<T>` being joined in. */
	public static function EntityOf(source:Expr):Type {
		final rows = EntitiesOf(source);
		if (rows.length != 1) {
			Context.error('Expected a source of one row type, got ${rows.length}', source.pos);
		}
		return rows[0];
	}
	#end
}
