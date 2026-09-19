package codequery.sqlexpressions;

/**
	Factory methods for the expression tree.

	What a macro emits is read far more often than it is written — in a stack trace, in a debugger,
	in the generated source of whichever target — so it is worth it reading as the condition it came
	from. `Expr.greaterThan(x, Expr.constInt(0))` says what
	`new BinarySqlExpression(x, SqlBinaryOperator.GreaterThan, new ConstSqlExpression(SqlConstInt(0)))`
	says, in a third of the width.

	Deliberately not `inline`: inlining these would put the constructor calls back.
**/
class Expr {
	public static function constInt(value:Int):ConstSqlExpression {
		return new ConstSqlExpression(SqlConstInt(value));
	}

	public static function constFloat(value:Float):ConstSqlExpression {
		return new ConstSqlExpression(SqlConstFloat(value));
	}

	public static function constString(value:String):ConstSqlExpression {
		return new ConstSqlExpression(SqlConstString(value));
	}

	public static function constBool(value:Bool):ConstSqlExpression {
		return new ConstSqlExpression(SqlConstBool(value));
	}

	public static function constNull():ConstSqlExpression {
		return new ConstSqlExpression(SqlConstNull);
	}

	public static function equal(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, Equal, right);
	}

	public static function notEqual(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, NotEqual, right);
	}

	public static function lessThan(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, LessThan, right);
	}

	public static function lessThanOrEqual(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, LessThanOrEqual, right);
	}

	public static function greaterThan(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, GreaterThan, right);
	}

	public static function greaterThanOrEqual(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, GreaterThanOrEqual, right);
	}

	public static function and(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, And, right);
	}

	public static function or(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, Or, right);
	}

	public static function add(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, Add, right);
	}

	public static function subtract(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, Subtract, right);
	}

	public static function multiply(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, Multiply, right);
	}

	public static function divide(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, Divide, right);
	}

	public static function modulo(left:ISqlExpression, right:ISqlExpression):BinarySqlExpression {
		return new BinarySqlExpression(left, Modulo, right);
	}
}
