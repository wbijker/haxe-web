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

	A lambda parameter stands for one of the statement's sources, and which source that is, is only
	known once the statement runs. So a converted predicate is emitted as a function of the sources:
	`Array<ISqlSource> -> ISqlExpression`, applied by the query against its own sources — the same
	binding C# does through `SourceContext`.
**/
class ExpressionConverter {
	#if macro
	/**
		Convert a predicate lambda into an expression building its `ISqlExpression`.

		`entity` is the row type the lambda's parameter stands for; the predicate is typed against
		it so that an editor can see inside the lambda and so the body is type-checked.
	**/
	public static function Convert(predicate:Expr, entity:Type):Expr {
		TypePredicate(predicate, entity);

		final fn = switch predicate.expr {
			case EFunction(_, f): f;
			case _: Context.error("A predicate must be a lambda, e.g. a -> a.id == 12", predicate.pos);
		}
		if (fn.args.length != 1) {
			Context.error("A predicate over one table takes exactly one parameter", predicate.pos);
		}

		// Parameter 0 is the statement's first source, exactly as in the C# converter.
		final aliases = [fn.args[0].name => 0];
		final body = ToSqlExpression(fn.expr, aliases, entity);
		return macro(sources : Array<codequery.sqlexpressions.ISqlSource>) -> $body;
	}

	/**
		Type the predicate against `entity -> Bool` and throw the result away.

		Nothing else types it — the tree is read as syntax — and Haxe answers completion, hover and
		go-to-definition while *typing* an expression. Without this an editor has nothing to offer
		inside the lambda. The typed expression is discarded, so none of it reaches the output.
	**/
	static function TypePredicate(predicate:Expr, entity:Type):Void {
		final row = entity.toComplexType();
		final signature = ComplexType.TFunction([row], macro :Bool);
		Context.typeExpr(macro @:pos(predicate.pos) ($predicate : $signature));
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
	static function ToSqlExpression(e:Expr, aliases:Map<String, Int>, entity:Type):Expr {
		final e = Unwrap(e);
		return switch e.expr {
			case EBinop(op, left, right):
				final sqlOp = ToSqlOperator(op, e.pos);
				final l = ToSqlExpression(left, aliases, entity);
				final r = ToSqlExpression(right, aliases, entity);
				macro new codequery.sqlexpressions.BinarySqlExpression($l, $sqlOp, $r);

			case EField(owner, field, _):
				switch Unwrap(owner).expr {
					case EConst(CIdent(name)) if (aliases.exists(name)):
						final index = aliases[name];
						final column = ColumnOf(field, entity, e.pos);
						macro new codequery.sqlexpressions.ColumnSqlExpression(sources[$v{index}], $v{column});
					case _:
						Context.error('Only a column of the row this predicate is written over can be used here', e.pos);
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
		The column a field maps to: its `@columnName`, else the field's own name — the same rule the
		C# inspector applies to a property. Checked against the row type, so a typo is a compile error.
	**/
	static function ColumnOf(field:String, entity:Type, pos:Position):String {
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case _: Context.error('${entity.toString()} is not a class, so it has no columns', pos);
		}
		for (f in row.fields.get()) {
			if (f.name == field) {
				final named = f.meta.extract("columnName");
				return switch named {
					case [{params: [{expr: EConst(CString(name, _))}]}]: name;
					case _: f.name;
				}
			}
		}
		return Context.error('${row.name} has no field "$field"', pos);
	}

	/** The row type a query is over, read from the static type of the query itself. */
	public static function EntityOf(query:Expr):Type {
		return switch Context.typeof(query).follow() {
			case TAbstract(_, [row]): row;
			case TInst(_, [row]): row;
			case t: Context.error('Cannot tell what row type this query is over: ${t.toString()}', query.pos);
		}
	}
	#end
}
