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

	static function ConvertLambda(lambda:Expr, rows:Array<Type>, returns:ComplexType, expected:String):Expr {
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

	/** Strip the syntax that carries no meaning for the conversion. */
	static function Unwrap(e:Expr):Expr {
		return switch e.expr {
			case EReturn(inner) if (inner != null): Unwrap(inner);
			case EParenthesis(inner): Unwrap(inner);
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
				final sqlOp = ToSqlOperator(op, e.pos);
				final l = ToSqlExpression(left, bound, rows);
				final r = ToSqlExpression(right, bound, rows);
				macro new codequery.sqlexpressions.BinarySqlExpression($l, $sqlOp, $r);

			case EField(owner, field, _):
				switch Unwrap(owner).expr {
					case EConst(CIdent(name)) if (bound.exists(name)):
						final index = bound[name];
						final row = rows[index];
						ColumnsBuilder.Member(ColumnsBuilder.Of(row, index), ColumnOf(field, row, e.pos));
					case _:
						Context.error('Only a column of a row this lambda is written over can be used here', e.pos);
				}

			case EConst(CInt(v, _)):
				macro new codequery.sqlexpressions.ConstSqlExpression(SqlConstInt($v{Std.parseInt(v)}));

			case EConst(CFloat(v, _)):
				macro new codequery.sqlexpressions.ConstSqlExpression(SqlConstFloat($v{Std.parseFloat(v)}));

			case EConst(CString(s, _)):
				macro new codequery.sqlexpressions.ConstSqlExpression(SqlConstString($v{s}));

			case EConst(CIdent("true")):
				macro new codequery.sqlexpressions.ConstSqlExpression(SqlConstBool(true));

			case EConst(CIdent("false")):
				macro new codequery.sqlexpressions.ConstSqlExpression(SqlConstBool(false));

			case EConst(CIdent("null")):
				macro new codequery.sqlexpressions.ConstSqlExpression(SqlConstNull);

			// A negative literal is unary minus over a positive one, not a constant of its own.
			case EUnop(OpNeg, false, {expr: EConst(CInt(v, _))}):
				macro new codequery.sqlexpressions.ConstSqlExpression(SqlConstInt($v{-Std.parseInt(v)}));

			case _:
				Context.error('Cannot convert to SQL: ${e.toString()}', e.pos);
		}
	}

	static function ToSqlOperator(op:Binop, pos:Position):Expr {
		final name = switch op {
			case OpEq: "Equal";
			case OpNotEq: "NotEqual";
			case OpLt: "LessThan";
			case OpLte: "LessThanOrEqual";
			case OpGt: "GreaterThan";
			case OpGte: "GreaterThanOrEqual";
			case OpBoolAnd: "And";
			case OpBoolOr: "Or";
			case OpAdd: "Add";
			case OpSub: "Subtract";
			case OpMult: "Multiply";
			case OpDiv: "Divide";
			case OpMod: "Modulo";
			case _: Context.error('Operator ${new Printer().printBinop(op)} has no SQL equivalent', pos);
		}
		return macro $p{["codequery", "sqlexpressions", "SqlBinaryOperator", name]};
	}

	/**
		Checks that the row really has this field, so that a typo is a compile error here rather than
		a confusing one about the generated columns type. Answers with the field's own name, which is
		what that type calls its member; the column name it maps to is settled there.
	**/
	static function ColumnOf(field:String, entity:Type, pos:Position):String {
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case _: Context.error('${entity.toString()} is not a class, so it has no columns', pos);
		}
		for (f in row.fields.get()) {
			if (f.name == field) {
				return f.name;
			}
		}
		return Context.error('${row.name} has no field "$field"', pos);
	}

	/** Whether an optional macro argument was left out at the call site. */
	public static function Omitted(arg:Null<Expr>):Bool {
		return arg == null || arg.expr.match(EConst(CIdent("null")));
	}

	/**
		A join: the source brings a row, the condition is written over the rows of both sides, and
		which runtime method is called depends on whether the source is a table or another query.
	**/
	public static function Join(self:Expr, source:Expr, on:Null<Expr>, joinType:String):Expr {
		final rows = EntitiesOf(self).concat([EntityOf(source)]);
		final kind = macro $p{["codequery", "sqlexpressions", "JoinType", joinType]};
		final condition = on == null ? macro null : Convert(on, rows);

		return IsTable(source)
			? macro $self.JoinTable($kind, $source, $condition)
			: macro $self.JoinQuery($kind, $source, $condition);
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

	/** The nulls ordering an `OrderBy` was given, or `Default` where it was left out. */
	public static function NullsOrDefault(nulls:Null<Expr>):Expr {
		return Omitted(nulls) ? macro codequery.sqlexpressions.NullsOrdering.Default : nulls;
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
