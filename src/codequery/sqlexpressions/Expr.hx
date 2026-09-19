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
	// Each takes a value that may be absent, so that a nullable column needs no special case
	// wherever a row's values are read.
	public static function constInt(value:Null<Int>):ConstSqlExpression {
		return value == null ? constNull() : new ConstSqlExpression(SqlConstInt(value));
	}

	public static function constFloat(value:Null<Float>):ConstSqlExpression {
		return value == null ? constNull() : new ConstSqlExpression(SqlConstFloat(value));
	}

	public static function constString(value:Null<String>):ConstSqlExpression {
		return value == null ? constNull() : new ConstSqlExpression(SqlConstString(value));
	}

	public static function constBool(value:Null<Bool>):ConstSqlExpression {
		return value == null ? constNull() : new ConstSqlExpression(SqlConstBool(value));
	}

	public static function constDate(value:Null<Date>):ConstSqlExpression {
		return value == null ? constNull() : new ConstSqlExpression(SqlConstDate(value));
	}

	public static function constNull():ConstSqlExpression {
		return new ConstSqlExpression(SqlConstNull);
	}

	public static function not(operand:ISqlExpression):NotSqlExpression {
		return new NotSqlExpression(operand);
	}

	public static function isIn(value:ISqlExpression, values:Array<ISqlExpression>, negate:Bool = false):InSqlExpression {
		return new InSqlExpression(value, values, null, negate);
	}

	public static function inQuery(value:ISqlExpression, subquery:SelectExpression, negate:Bool = false):InSqlExpression {
		return new InSqlExpression(value, [], subquery, negate);
	}

	public static function between(value:ISqlExpression, lower:ISqlExpression, upper:ISqlExpression,
			negate:Bool = false):BetweenSqlExpression {
		return new BetweenSqlExpression(value, lower, upper, negate);
	}

	public static function isDistinctFrom(left:ISqlExpression, right:ISqlExpression,
			negate:Bool = false):IsDistinctFromSqlExpression {
		return new IsDistinctFromSqlExpression(left, right, negate);
	}

	public static function caseWhen(branches:Array<CaseBranch>, ?otherwise:ISqlExpression):CaseSqlExpression {
		return new CaseSqlExpression(branches, otherwise);
	}

	/** `CASE <operand> WHEN <value> THEN …` — one operand compared against each arm's value. */
	public static function simpleCase(operand:ISqlExpression, branches:Array<CaseBranch>,
			?otherwise:ISqlExpression):CaseSqlExpression {
		return new CaseSqlExpression(branches, otherwise, operand);
	}

	public static function exists(subquery:SelectExpression, negate:Bool = false):ExistsSqlExpression {
		return new ExistsSqlExpression(subquery, negate);
	}

	/** `s.contains(term)`, `s.startsWith(term)`, `s.endsWith(term)` — a LIKE the translator adds the wildcards to. */
	public static function stringOp(type:StringOperationType, operand:ISqlExpression,
			pattern:ISqlExpression):StringOperationExpression {
		return new StringOperationExpression(type, operand, pattern);
	}

	/** `(a, b, …)` — several values as one row. */
	public static function row(values:Array<ISqlExpression>):RowSqlExpression {
		return new RowSqlExpression(values);
	}

	/**
		`a AND b` where a side may be decided already — a captured flag, a guard on a captured list.
		A decided side folds away, and the other is only built where it is needed: `false && x` never
		looks at `x`, which is what lets a guard stand in front of something that could not be built
		on its own.
	**/
	public static function andAlso(left:ISqlExpression, right:Void->ISqlExpression):ISqlExpression {
		final decided = Decided(left);
		if (decided != null) {
			return decided ? right() : constBool(false);
		}
		final other = right();
		final otherDecided = Decided(other);
		if (otherDecided != null) {
			return otherDecided ? left : constBool(false);
		}
		return and(left, other);
	}

	/** `a OR b`, with a decided side folded away as `andAlso` does: `true || x` never looks at `x`. */
	public static function orElse(left:ISqlExpression, right:Void->ISqlExpression):ISqlExpression {
		final decided = Decided(left);
		if (decided != null) {
			return decided ? constBool(true) : right();
		}
		final other = right();
		final otherDecided = Decided(other);
		if (otherDecided != null) {
			return otherDecided ? constBool(true) : left;
		}
		return or(left, other);
	}

	/** What a side already says, where it is a boolean the query holds — written in, or bound. */
	static function Decided(e:ISqlExpression):Null<Bool> {
		final constant = Std.downcast(cast e, ConstSqlExpression);
		if (constant != null) {
			return switch constant.Value {
				case SqlConstBool(v): v;
				case _: null;
			}
		}
		final parameter = Std.downcast(cast e, SqlParameterExpression);
		if (parameter != null) {
			return switch parameter.Value {
				case SqlConstBool(v): v;
				case _: null;
			}
		}
		return null;
	}

	public static function branch(when:ISqlExpression, then:ISqlExpression):CaseBranch {
		return new CaseBranch(when, then);
	}

	/** A function written as `name(a, b)`. */
	public static function call(name:String, arguments:Array<ISqlExpression>):SqlFunctionExpression {
		return new SqlFunctionExpression(name, arguments);
	}

	/** A function written between its arguments, as `||` is. */
	public static function infix(name:String, arguments:Array<ISqlExpression>):SqlFunctionExpression {
		return new SqlFunctionExpression(name, arguments, true);
	}

	public static function castTo(value:ISqlExpression, type:SqlType):SqlCastExpression {
		return new SqlCastExpression(value, type);
	}

	public static function raw(sql:String):RawSqlExpression {
		return new RawSqlExpression(sql);
	}

	public static function scalar(subquery:SelectExpression, correlated:Bool = false):ScalarSubquerySqlExpression {
		return new ScalarSubquerySqlExpression(subquery, correlated);
	}

	public static function quantified(value:ISqlExpression, op:SqlBinaryOperator, quantifier:Quantifier,
			subquery:SelectExpression):QuantifiedComparisonSqlExpression {
		return new QuantifiedComparisonSqlExpression(value, op, quantifier, subquery);
	}

	/** A value sent beside the statement rather than written into it. */
	public static function param(value:SqlConstValue):SqlParameterExpression {
		return new SqlParameterExpression(value);
	}

	public static function paramInt(value:Null<Int>):ISqlExpression {
		return value == null ? constNull() : param(SqlConstInt(value));
	}

	public static function paramFloat(value:Null<Float>):ISqlExpression {
		return value == null ? constNull() : param(SqlConstFloat(value));
	}

	public static function paramString(value:Null<String>):ISqlExpression {
		return value == null ? constNull() : param(SqlConstString(value));
	}

	public static function paramBool(value:Null<Bool>):ISqlExpression {
		return value == null ? constNull() : param(SqlConstBool(value));
	}

	public static function paramDate(value:Null<Date>):ISqlExpression {
		return value == null ? constNull() : param(SqlConstDate(value));
	}

	/**
		The same column, read one statement further out.

		What a lateral's inner query needs to say about the row it is joined to: the column is the
		outer statement's, not its own.
	**/
	public static function outer(column:ColumnSqlExpression):ColumnSqlExpression {
		final parameter = Std.downcast(cast column.Source, ParameterSqlSource);
		if (parameter == null) {
			throw "Only a column bound to a lambda's parameter can be read from further out";
		}
		return new ColumnSqlExpression(ParameterSqlSource.At(parameter.Index, parameter.Scope + 1),
			column.ColumnName, column.ColumnType);
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
