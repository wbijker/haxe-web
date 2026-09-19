package sql;

import haxe.macro.Expr;
#if macro
import haxe.macro.Context;
import haxe.macro.Printer;
import haxe.macro.Type;

using haxe.macro.ExprTools;
#end

/**
	The Haxe answer to C#'s `string Where(Expression<Func<Delivery, bool>> predicate)`.

	C# reifies the lambda into an `Expression` tree at runtime and walks it there.
	A Haxe macro gets the syntax tree at *compile time* instead, so the whole
	analysis happens during compilation and the call site is left holding nothing
	but the finished SQL string.
**/
class Query {
	/**
		Translate `d -> d.id > 10` into `d.Id > 10`.

		Unknown fields, unsupported operators and references to anything other
		than the lambda parameter are compile errors, pointed at the offending
		part of the predicate.
	**/
	public static macro function where(predicate:ExprOf<model.Delivery->Bool>):ExprOf<String> {
		return macro $v{parsePredicate(predicate).toSql()};
	}

	#if macro
	/** The entity the predicate is written against. */
	static inline final ENTITY = "model.Delivery";

	/** Pull the parameter name and body out of the lambda, then translate the body. */
	static function parsePredicate(predicate:Expr):SqlExpression {
		final fn = switch predicate.expr {
			case EFunction(_, f): f;
			case _: Context.error("where() expects a lambda, e.g. d -> d.id > 10", predicate.pos);
		}
		if (fn.args.length != 1) {
			Context.error("where() expects a lambda taking exactly one parameter", predicate.pos);
		}
		return toSqlAst(fn.expr, fn.args[0].name);
	}

	/** Strip the syntactic noise that carries no meaning for us. */
	static function unwrap(e:Expr):Expr {
		return switch e.expr {
			case EReturn(inner) if (inner != null): unwrap(inner);
			case EParenthesis(inner): unwrap(inner);
			case EMeta(_, inner): unwrap(inner);
			case EBlock([inner]): unwrap(inner);
			case _: e;
		}
	}

	/** Haxe syntax tree in, SQL expression tree out. */
	static function toSqlAst(e:Expr, alias:String):SqlExpression {
		final e = unwrap(e);
		return switch e.expr {
			case EBinop(op, left, right):
				new BinaryExpression(toSqlAst(left, alias), toSqlOperator(op, e.pos), toSqlAst(right, alias));

			case EField(owner, field, _):
				switch unwrap(owner).expr {
					case EConst(CIdent(name)) if (name == alias):
						new ColumnExpression(alias, columnOf(field, e.pos));
					case _:
						Context.error('Only fields of the lambda parameter "$alias" can be used as columns', e.pos);
				}

			case EConst(CInt(v, _)):
				new ConstIntExpression(Std.parseInt(v));

			case EConst(CString(s, _)):
				new ConstStringExpression(s);

			case EConst(CIdent("true")):
				new ConstBoolExpression(true);

			case EConst(CIdent("false")):
				new ConstBoolExpression(false);

			// Literals only: `-5` is unary minus applied to `5`, not a constant.
			case EUnop(OpNeg, false, {expr: EConst(CInt(v, _))}):
				new ConstIntExpression(-Std.parseInt(v));

			case _:
				Context.error('Unsupported expression in where(): ${e.toString()}', e.pos);
		}
	}

	static function toSqlOperator(op:Binop, pos:Position):SqlBinaryOperator {
		return switch op {
			case OpEq: Eq;
			case OpNotEq: NotEq;
			case OpGt: Gt;
			case OpGte: Gte;
			case OpLt: Lt;
			case OpLte: Lte;
			case OpBoolAnd: And;
			case OpBoolOr: Or;
			case _: Context.error('Operator ${new Printer().printBinop(op)} has no SQL equivalent', pos);
		}
	}

	/**
		Map a Haxe field onto its column, checking against the real type so that
		a typo is a compile error rather than a runtime SQL failure. The C#
		originals are PascalCase, so that is the mapping.
	**/
	static function columnOf(field:String, pos:Position):String {
		final entity = switch Context.getType(ENTITY) {
			case TInst(t, _): t.get();
			case _: Context.error('$ENTITY is not a class', pos);
		}
		for (f in entity.fields.get()) {
			if (f.name == field) {
				return field.charAt(0).toUpperCase() + field.substr(1);
			}
		}
		return Context.error('${entity.name} has no field "$field"', pos);
	}
	#end
}
