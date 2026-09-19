package codequery.migrations;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;
#end

/**
	Renders a predicate lambda — `r -> r.rating >= 1 && r.rating <= 5` — as the text of a CHECK:
	`rating >= 1 AND rating <= 5`. The C# class of the same name, which reads an expression tree
	at runtime; here the lambda is read while compiling, and becomes the code that builds the text.

	A member of the lambda's parameter is a column; a constant is written as one; anything else —
	a captured value, say — is read when the code runs and written as the constant it then is,
	which is what the runtime `Constant` is for.
**/
class CheckExpressionRenderer {
	/** A value as a CHECK writes it: quoted text, `1`/`0` for a boolean, `NULL` for nothing. */
	public static function Constant(value:Dynamic):String {
		if (value == null) {
			return "NULL";
		}
		if (Std.isOfType(value, Bool)) {
			return (value : Bool) ? "1" : "0";
		}
		if (Std.isOfType(value, String)) {
			return "'" + StringTools.replace((value : String), "'", "''") + "'";
		}
		return Std.string(value);
	}

	#if macro
	/** An expression of type `String`: the check written over the entity's columns. */
	public static function RenderEntity(lambda:Expr, pos:Position):Expr {
		final fn = Lambda(lambda);
		return Join(Parts(fn.expr, fn.args[0].name, null), pos);
	}

	/**
		A function from the column's name to the check, for a check written over one column's value:
		`r -> r >= 1` gives `<column> >= 1`, whichever name the column has by the time it is asked.
	**/
	public static function RenderColumn(lambda:Expr, pos:Position):Expr {
		final fn = Lambda(lambda);
		final body = Join(Parts(fn.expr, fn.args[0].name, "__column"), pos);
		return macro function(__column:String):String return $body;
	}

	static function Lambda(lambda:Expr):Function {
		return switch lambda.expr {
			case EFunction(_, f) if (f.args.length == 1): f;
			case EParenthesis(inner): Lambda(inner);
			case _: Context.error("Expected a predicate over one parameter, e.g. r -> r.rating >= 1", lambda.pos);
		}
	}

	/** The text as pieces: literal SQL, and expressions whose value is only known when it runs. */
	static function Parts(e:Expr, parameter:String, column:Null<String>):Array<Part> {
		return switch e.expr {
			case EParenthesis(inner) | EMeta(_, inner) | ECheckType(inner, _) | EReturn(inner) | EBlock([inner]):
				Parts(inner, parameter, column);

			case EBinop(op, left, right):
				final symbol = switch op {
					case OpBoolAnd: "AND";
					case OpBoolOr: "OR";
					case OpEq: "=";
					case OpNotEq: "<>";
					case OpLt: "<";
					case OpLte: "<=";
					case OpGt: ">";
					case OpGte: ">=";
					case OpAdd: "+";
					case OpSub: "-";
					case OpMult: "*";
					case OpDiv: "/";
					case OpMod: "%";
					case _: Context.error('Operator ${op} is not supported in check expressions', e.pos);
				}
				if (IsNull(right)) {
					final test = switch op {
						case OpEq: " IS NULL";
						case OpNotEq: " IS NOT NULL";
						case _: Context.error('Operator ${op} against NULL is not supported', e.pos);
					}
					Parts(left, parameter, column).concat([Literal(test)]);
				} else {
					Parts(left, parameter, column).concat([Literal(' $symbol ')]).concat(Parts(right, parameter, column));
				}

			case EUnop(OpNot, false, operand):
				[Literal("NOT (")].concat(Parts(operand, parameter, column)).concat([Literal(")")]);

			case EUnop(OpNeg, false, operand):
				[Literal("-")].concat(Parts(operand, parameter, column));

			// A member of the parameter is a column, named for the field as C# names it for the property.
			case EField({expr: EConst(CIdent(name))}, field, _) if (name == parameter):
				[Literal(field)];

			case EConst(CIdent(name)) if (name == parameter && column != null):
				[Runtime(macro $i{column})];

			case EConst(CIdent(name)) if (name == parameter):
				Context.error("A check over the entity names its columns, e.g. r -> r.rating >= 1", e.pos);

			case EConst(CIdent("null")): [Literal("NULL")];
			case EConst(CIdent("true")): [Literal("1")];
			case EConst(CIdent("false")): [Literal("0")];
			case EConst(CInt(v, _)) | EConst(CFloat(v, _)): [Literal(v)];
			case EConst(CString(s, _)): [Literal("'" + StringTools.replace(s, "'", "''") + "'")];

			case _:
				// A constant the compiler already knows — an enum abstract's member — else a value read as it runs.
				final known = ConstantOf(e);
				known != null ? [Literal(known)] : [Runtime(macro codequery.migrations.CheckExpressionRenderer.Constant($e))];
		}
	}

	static function IsNull(e:Expr):Bool {
		return switch e.expr {
			case EConst(CIdent("null")): true;
			case EParenthesis(inner): IsNull(inner);
			case _: false;
		}
	}

	static function ConstantOf(e:Expr):Null<String> {
		final typed = try Context.typeExpr(e) catch (_:Dynamic) return null;
		return switch Unwrap(typed).expr {
			case TConst(TInt(v)): Std.string(v);
			case TConst(TFloat(v)): v;
			case TConst(TString(v)): "'" + StringTools.replace(v, "'", "''") + "'";
			case TConst(TBool(v)): v ? "1" : "0";
			case TConst(TNull): "NULL";
			case _: null;
		}
	}

	static function Unwrap(e:haxe.macro.Type.TypedExpr):haxe.macro.Type.TypedExpr {
		return switch e.expr {
			case TCast(inner, _) | TMeta(_, inner) | TParenthesis(inner): Unwrap(inner);
			case TField(_, FStatic(_, cf)):
				final member = cf.get().expr();
				member == null ? e : Unwrap(member);
			case _: e;
		}
	}

	/** The pieces as one string expression, with neighbouring literals folded together. */
	static function Join(parts:Array<Part>, pos:Position):Expr {
		final folded:Array<Part> = [];
		for (part in parts) {
			switch [folded.length > 0 ? folded[folded.length - 1] : null, part] {
				case [Literal(a), Literal(b)]: folded[folded.length - 1] = Literal(a + b);
				case _: folded.push(part);
			}
		}
		var joined:Null<Expr> = null;
		for (part in folded) {
			final piece = switch part {
				case Literal(text): macro $v{text};
				case Runtime(e): e;
			}
			joined = joined == null ? piece : macro $joined + $piece;
		}
		return joined == null ? macro "" : joined;
	}
	#end
}

#if macro
enum Part {
	Literal(text:String);
	Runtime(e:Expr);
}
#end
