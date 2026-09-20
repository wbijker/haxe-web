package codequery.sqldrivers;

import codequery.sqlexpressions.AggregateSqlExpression;
import codequery.sqlexpressions.AllColumnsSqlExpression;
import codequery.sqlexpressions.BetweenSqlExpression;
import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.CaseSqlExpression;
import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.DateFormatSqlExpression;
import codequery.sqlexpressions.DateOperationSqlExpression;
import codequery.sqlexpressions.DistinctSqlExpression;
import codequery.sqlexpressions.IntervalSqlExpression;
import codequery.sqlexpressions.ObjectConstSqlExpression;
import codequery.sqlexpressions.RowSqlExpression;
import codequery.sqlexpressions.SqlCommentExpression;
import codequery.sqlexpressions.StringOperationExpression;
import codequery.sqlexpressions.ExistsSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.ISqlExpressionVisitor;
import codequery.sqlexpressions.InSqlExpression;
import codequery.sqlexpressions.IsDistinctFromSqlExpression;
import codequery.sqlexpressions.NotSqlExpression;
import codequery.sqlexpressions.OrderByExpression;
import codequery.sqlexpressions.ProjectionSqlExpression;
import codequery.sqlexpressions.QuantifiedComparisonSqlExpression;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.ScalarSubquerySqlExpression;
import codequery.sqlexpressions.SqlBinaryOperator;
import codequery.sqlexpressions.SqlCastExpression;
import codequery.sqlexpressions.SqlConstValue;
import codequery.sqlexpressions.SqlExpressionWalker;
import codequery.sqlexpressions.SqlFunctionExpression;
import codequery.sqlexpressions.SqlParameterExpression;
import codequery.sqlexpressions.SqlType;
import codequery.sqlexpressions.WindowFunctionExpression;

/**
	A stable, provider-neutral rendering of an expression — the C# `AnsiSqlTranslator`.

	What a schema snapshot records for a column's default or a generated column's expression, so it
	belongs to no dialect: identifiers in the standard's double quotes, `CURRENT_TIMESTAMP` for
	whatever `NOW()` a driver would write. The same renderer, told not to quote, is what the generic
	DDL writes, since a column in a CHECK or a DEFAULT names no source and takes no alias.
**/
class AnsiSqlRenderer implements ISqlExpressionVisitor<String> {
	final quoted:Bool;

	public function new(quoted:Bool = true) {
		this.quoted = quoted;
	}

	public function Render(e:ISqlExpression):String {
		return SqlExpressionWalker.Visit(e, this);
	}

	/** An identifier as this rendering writes it. */
	public function Identifier(name:String):String {
		return quoted ? '"$name"' : name;
	}

	public function OnColumn(e:ColumnSqlExpression):String {
		return Identifier(e.ColumnName);
	}

	public function OnAllColumns(e:AllColumnsSqlExpression):String {
		return "*";
	}

	public function OnConst(e:ConstSqlExpression):String {
		return Constant(e.Value);
	}

	/** A literal in the standard's own spelling. */
	public static function Constant(value:SqlConstValue):String {
		return switch value {
			case SqlConstBool(v): v ? "TRUE" : "FALSE";
			case SqlConstInt(v): Std.string(v);
			case SqlConstFloat(v): Std.string(v);
			case SqlConstString(v): "'" + StringTools.replace(v, "'", "''") + "'";
			case SqlConstDate(v): "'" + DateTools.format(v, "%Y-%m-%d %H:%M:%S") + "'";
			case SqlConstNull: "NULL";
		}
	}

	public function OnParameter(e:SqlParameterExpression):String {
		return Constant(e.Value);
	}

	public function OnBinary(e:BinarySqlExpression):String {
		final nullTest = NullTest(e);
		if (nullTest != null) {
			return '($nullTest)';
		}
		return '(${Render(e.Left)} ${Operator(e.Operator)} ${Render(e.Right)})';
	}

	function NullTest(e:BinarySqlExpression):Null<String> {
		final negated = switch e.Operator {
			case Equal: false;
			case NotEqual: true;
			case _: return null;
		}
		final operand = IsNull(e.Left) ? e.Right : (IsNull(e.Right) ? e.Left : null);
		return operand == null ? null : '${Render(operand)} IS ${negated ? "NOT " : ""}NULL';
	}

	static function IsNull(e:ISqlExpression):Bool {
		final constant = Std.downcast(cast e, ConstSqlExpression);
		return constant != null && constant.Value.match(SqlConstNull);
	}

	public static function Operator(op:SqlBinaryOperator):String {
		return switch op {
			case Equal: "=";
			case NotEqual: "<>";
			case LessThan: "<";
			case LessThanOrEqual: "<=";
			case GreaterThan: ">";
			case GreaterThanOrEqual: ">=";
			case And: "AND";
			case Or: "OR";
			case Add: "+";
			case Subtract: "-";
			case Multiply: "*";
			case Divide: "/";
			case Modulo: "%";
		}
	}

	public function OnNot(e:NotSqlExpression):String {
		return 'NOT (${Render(e.Operand)})';
	}

	public function OnIn(e:InSqlExpression):String {
		if (e.Subquery != null) {
			throw "A subquery has no canonical rendering";
		}
		final keyword = e.Negate ? "NOT IN" : "IN";
		return '${Render(e.Value)} $keyword (${e.Values.map(Render).join(", ")})';
	}

	public function OnBetween(e:BetweenSqlExpression):String {
		final keyword = e.Negate ? "NOT BETWEEN" : "BETWEEN";
		return '${Render(e.Value)} $keyword ${Render(e.Lower)} AND ${Render(e.Upper)}';
	}

	public function OnIsDistinctFrom(e:IsDistinctFromSqlExpression):String {
		final keyword = e.Negate ? "IS NOT DISTINCT FROM" : "IS DISTINCT FROM";
		return '${Render(e.Left)} $keyword ${Render(e.Right)}';
	}

	public function OnCase(e:CaseSqlExpression):String {
		var sql = "CASE";
		for (branch in e.Branches) {
			sql += ' WHEN ${Render(branch.When)} THEN ${Render(branch.Then)}';
		}
		if (e.Otherwise != null) {
			sql += ' ELSE ${Render(e.Otherwise)}';
		}
		return sql + " END";
	}

	public function OnFunction(e:SqlFunctionExpression):String {
		final arguments = e.Arguments.map(Render);
		return switch e.Name {
			// The standard's own spellings, which is what makes them the canonical form.
			case "NOW" | "Now": "CURRENT_TIMESTAMP";
			case "UTC_NOW" | "UtcNow": "CURRENT_TIMESTAMP AT TIME ZONE 'UTC'";
			case "TODAY" | "Today": "CURRENT_DATE";
			case "LENGTH": 'CHAR_LENGTH(${arguments.join(", ")})';
			case _ if (e.Infix): arguments.join(' ${e.Name} ');
			case _: '${e.Name}(${arguments.join(", ")})';
		}
	}

	public function OnCast(e:SqlCastExpression):String {
		return 'CAST(${Render(e.Value)} AS ${TypeName(e.Type)})';
	}

	/** A type in the standard's spelling. */
	public static function TypeName(type:SqlType):String {
		return switch type {
			case SqlInt: "INTEGER";
			case SqlBigInt: "BIGINT";
			case SqlSmallInt: "SMALLINT";
			case SqlReal: "REAL";
			case SqlFloat: "DOUBLE PRECISION";
			case SqlDecimal(precision, scale): 'DECIMAL($precision, $scale)';
			case SqlBool: "BOOLEAN";
			case SqlText: "TEXT";
			case SqlChar(length): length <= 0 ? "CHAR" : 'CHAR($length)';
			case SqlVarChar(length): length <= 0 ? "TEXT" : 'VARCHAR($length)';
			case SqlDate: "DATE";
			case SqlTime: "TIME";
			case SqlTimestamp: "TIMESTAMP";
			case SqlGuid: "UUID";
			case SqlBinary: "BLOB";
			case SqlJson: "JSON";
			case SqlNamed(name): name;
			case SqlUnknown: throw "A cast needs a type to cast to";
		}
	}

	public function OnRaw(e:RawSqlExpression):String {
		return e.Sql;
	}

	public function OnAggregate(e:AggregateSqlExpression):String {
		throw "An aggregate has no canonical rendering";
	}

	public function OnProjection(e:ProjectionSqlExpression):String {
		throw "A projection has no canonical rendering";
	}

	public function OnExists(e:ExistsSqlExpression):String {
		throw "A subquery has no canonical rendering";
	}

	public function OnScalarSubquery(e:ScalarSubquerySqlExpression):String {
		throw "A subquery has no canonical rendering";
	}

	public function OnQuantified(e:QuantifiedComparisonSqlExpression):String {
		throw "A subquery has no canonical rendering";
	}

	public function OnWindowFunction(e:WindowFunctionExpression):String {
		throw "A window function has no canonical rendering";
	}

	public function OnOrderBy(e:OrderByExpression):String {
		throw "An ordering has no canonical rendering";
	}

	public function OnObjectConst(e:ObjectConstSqlExpression):String {
		throw "An object value has no canonical rendering";
	}

	public function OnDistinct(e:DistinctSqlExpression):String {
		return 'DISTINCT ${Render(e.Value)}';
	}

	public function OnStringOperation(e:StringOperationExpression):String {
		throw "A string operation has no canonical rendering";
	}

	public function OnDateOperation(e:DateOperationSqlExpression):String {
		throw "A date operation has no canonical rendering";
	}

	public function OnDateFormat(e:DateFormatSqlExpression):String {
		throw "A date format has no canonical rendering";
	}

	public function OnInterval(e:IntervalSqlExpression):String {
		return FunctionRendering.Interval(e);
	}

	/** A comment says nothing the database compares, so the canonical form leaves it out. */
	public function OnComment(e:SqlCommentExpression):String {
		return Render(e.Value);
	}

	public function OnRow(e:RowSqlExpression):String {
		return '(${e.Values.map(Render).join(", ")})';
	}
}
