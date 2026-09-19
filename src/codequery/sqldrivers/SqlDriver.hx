package codequery.sqldrivers;

import codequery.sqlexpressions.AggregateSqlExpression;
import codequery.sqlexpressions.AllColumnsSqlExpression;
import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ExistsSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.ISqlSource;
import codequery.sqlexpressions.JoinSqlExpression;
import codequery.sqlexpressions.JoinType;
import codequery.sqlexpressions.NamedWindowSqlSource;
import codequery.sqlexpressions.OrderByExpression;
import codequery.sqlexpressions.ParameterSqlSource;
import codequery.sqlexpressions.ProjectionSqlExpression;
import codequery.sqlexpressions.QuerySqlSource;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SqlBinaryOperator;
import codequery.sqlexpressions.SqlConstValue;
import codequery.sqlexpressions.TableSqlSource;

/**
	Renders a statement as SQL. The C# original splits this into an `ISqlTranslator` that renders
	and an `ISqlDriver` that also knows where to send the result; only the rendering half is here.
**/
class SqlDriver {
	/**
		The statement being rendered, in the order a lambda's parameters bind to its sources. A
		generated column names its source by position, so rendering one is a lookup here.
	**/
	var sources:Array<ISqlSource> = [];

	public function new() {}

	public function ToSql(expression:SelectExpression):String {
		// Each statement renders against its own sources; a subquery restores the outer ones after.
		final outer = sources;
		sources = expression.AllSources();
		final sql = Statement(expression);
		sources = outer;
		return sql;
	}

	/** The statement itself, rendered against whichever sources are in scope. */
	function Statement(expression:SelectExpression):String {
		var sql = 'SELECT${Distinct(expression)} ${Selection(expression)} FROM ${Source(expression.Source)}';
		for (join in expression.Joins) {
			sql += " " + Join(join);
		}
		if (expression.Where != null) {
			sql += ' WHERE ${RenderExpression(expression.Where)}';
		}
		if (expression.GroupBy.length > 0) {
			sql += ' GROUP BY ${expression.GroupBy.map(RenderExpression).join(", ")}';
		}
		if (expression.Having != null) {
			sql += ' HAVING ${RenderExpression(expression.Having)}';
		}
		if (expression.Windows.length > 0) {
			sql += ' WINDOW ${expression.Windows.map(RenderWindowDefinition).join(", ")}';
		}
		if (expression.OrderBy.length > 0) {
			sql += ' ORDER BY ${expression.OrderBy.map(RenderOrderBy).join(", ")}';
		}
		sql += RowLimit(expression);
		return sql;
	}

	function Selection(expression:SelectExpression):String {
		return expression.Selection == null ? "*" : RenderExpression(expression.Selection);
	}

	function Source(source:ISqlSource):String {
		final window = Std.downcast(cast source, NamedWindowSqlSource);
		if (window != null) {
			throw "A window is named by the aggregates reading it, not selected from";
		}

		final table = Std.downcast(cast source, TableSqlSource);
		if (table != null) {
			return '${table.Table} AS ${table.Alias}';
		}

		final query = Std.downcast(cast source, QuerySqlSource);
		if (query != null) {
			return '(${ToSql(query.Query)}) AS ${query.Alias}';
		}

		throw 'Cannot render a source of ${Type.getClassName(Type.getClass(source))}';
	}

	function Join(join:JoinSqlExpression):String {
		final sql = '${JoinKeyword(join.Type)} ${Source(join.Source)}';
		return join.On == null ? sql : '$sql ON ${RenderExpression(join.On)}';
	}

	function JoinKeyword(type:JoinType):String {
		return switch type {
			case Inner: "INNER JOIN";
			case Left: "LEFT JOIN";
			case Right: "RIGHT JOIN";
			case Outer: "FULL OUTER JOIN";
			case Cross: "CROSS JOIN";
			case CrossLateral: "CROSS JOIN LATERAL";
			case LeftLateral: "LEFT JOIN LATERAL";
		}
	}

	function Distinct(expression:SelectExpression):String {
		if (expression.DistinctOn.length > 0) {
			return ' DISTINCT ON (${expression.DistinctOn.map(RenderExpression).join(", ")})';
		}
		return expression.IsDistinct ? " DISTINCT" : "";
	}

	function RenderOrderBy(term:OrderByExpression):String {
		final sql = '${RenderExpression(term.Expression)} ${term.Ascending ? "ASC" : "DESC"}';
		return switch term.Nulls {
			case Default: sql;
			case First: '$sql NULLS FIRST';
			case Last: '$sql NULLS LAST';
		}
	}

	/**
		`LIMIT`/`OFFSET` says it in the fewest words, but neither can express ties or a percentage,
		so a query asking for either is rendered in the standard's longer form instead.
	**/
	function RowLimit(expression:SelectExpression):String {
		if (!expression.WithTies && !expression.Percent) {
			var sql = "";
			if (expression.Limit != null) {
				sql += ' LIMIT ${expression.Limit}';
			}
			if (expression.Offset != null) {
				sql += ' OFFSET ${expression.Offset}';
			}
			return sql;
		}

		var sql = "";
		if (expression.Offset != null) {
			sql += ' OFFSET ${expression.Offset} ROWS';
		}
		if (expression.Limit != null) {
			final percent = expression.Percent ? " PERCENT" : "";
			final ties = expression.WithTies ? "WITH TIES" : "ONLY";
			sql += ' FETCH NEXT ${expression.Limit}$percent ROWS $ties';
		}
		return sql;
	}

	/**
		The C# original dispatches through `ISqlExpressionVisitor`; a downcast chain says the same
		thing for the node kinds that exist so far.
	**/
	function RenderExpression(e:ISqlExpression):String {
		final column = Std.downcast(cast e, ColumnSqlExpression);
		if (column != null) {
			return '${AliasOf(column.Source)}.${column.ColumnName}';
		}

		final constant = Std.downcast(cast e, ConstSqlExpression);
		if (constant != null) {
			return RenderConst(constant.Value);
		}

		final binary = Std.downcast(cast e, BinarySqlExpression);
		if (binary != null) {
			final nullTest = NullTest(binary);
			return nullTest != null
				? nullTest
				: '${Operand(binary, binary.Left)} ${RenderOperator(binary.Operator)} ${Operand(binary, binary.Right)}';
		}

		final aggregate = Std.downcast(cast e, AggregateSqlExpression);
		if (aggregate != null) {
			return RenderAggregate(aggregate);
		}

		final all = Std.downcast(cast e, AllColumnsSqlExpression);
		if (all != null) {
			return '${AliasOf(all.Source)}.*';
		}

		final projection = Std.downcast(cast e, ProjectionSqlExpression);
		if (projection != null) {
			return projection.Members
				.map(member -> '${RenderExpression(member.Expression)} AS ${member.Name}')
				.join(", ");
		}

		final exists = Std.downcast(cast e, ExistsSqlExpression);
		if (exists != null) {
			// Correlated: the subquery can name the outer statement's rows, so its sources are
			// added to them rather than replacing them.
			final outer = sources;
			sources = sources.concat(exists.Subquery.AllSources());
			final sql = '${exists.Negate ? "NOT EXISTS" : "EXISTS"} (${Statement(exists.Subquery)})';
			sources = outer;
			return sql;
		}

		throw 'Cannot render ${Type.getClassName(Type.getClass(e))}';
	}

	function RenderAggregate(aggregate:AggregateSqlExpression):String {
		final name = switch aggregate.Type {
			case Count: "COUNT";
			case Sum: "SUM";
			case Avg: "AVG";
			case Min: "MIN";
			case Max: "MAX";
		}
		final distinct = aggregate.Distinct ? "DISTINCT " : "";
		// COUNT with nothing to count counts rows.
		final argument = aggregate.Argument == null ? "*" : RenderExpression(aggregate.Argument);
		final sql = '$name($distinct$argument)';
		return aggregate.Window == null ? sql : '$sql OVER ${aggregate.Window.Name}';
	}

	function RenderWindowDefinition(window:NamedWindowSqlSource):String {
		final parts = [];
		if (window.PartitionBy.length > 0) {
			parts.push('PARTITION BY ${window.PartitionBy.map(RenderExpression).join(", ")}');
		}
		if (window.OrderBy.length > 0) {
			parts.push('ORDER BY ${window.OrderBy.map(RenderOrderBy).join(", ")}');
		}
		return '${window.Name} AS (${parts.join(" ")})';
	}

	/**
		The alias a column renders under. A generated column names its source by the position of the
		lambda parameter it was reached through, which is only meaningful against a statement — so
		this is where the two are put together.
	**/
	function AliasOf(source:ISqlSource):String {
		final parameter = Std.downcast(cast source, ParameterSqlSource);
		if (parameter == null) {
			return source.Alias;
		}
		if (parameter.Index >= sources.length) {
			throw 'This statement has ${sources.length} source(s), so it has no row ${parameter.Index}';
		}
		return sources[parameter.Index].Alias;
	}

	/**
		`x IS NULL` rather than `x = NULL`.

		Nothing equals NULL in SQL, not even NULL — a comparison against it is neither true nor
		false but unknown, so `= NULL` quietly matches no row at all. Written as a comparison,
		meant as a test, and rendered as one.
	**/
	function NullTest(binary:BinarySqlExpression):Null<String> {
		final negated = switch binary.Operator {
			case Equal: false;
			case NotEqual: true;
			case _: return null;
		}

		final operand = IsNull(binary.Left) ? binary.Right : (IsNull(binary.Right) ? binary.Left : null);
		if (operand == null) {
			return null;
		}
		return '${RenderExpression(operand)} IS ${negated ? "NOT NULL" : "NULL"}';
	}

	function IsNull(e:ISqlExpression):Bool {
		final constant = Std.downcast(cast e, ConstSqlExpression);
		return constant != null && constant.Value.match(SqlConstNull);
	}

	/** Parenthesise a child only where precedence needs it. */
	function Operand(parent:BinarySqlExpression, child:ISqlExpression):String {
		final nested = Std.downcast(cast child, BinarySqlExpression);
		final sql = RenderExpression(child);
		return (nested != null && Precedence(nested.Operator) < Precedence(parent.Operator)) ? '($sql)' : sql;
	}

	function Precedence(op:SqlBinaryOperator):Int {
		return switch op {
			case Or: 1;
			case And: 2;
			case Equal | NotEqual | LessThan | LessThanOrEqual | GreaterThan | GreaterThanOrEqual: 3;
			case Add | Subtract: 4;
			case Multiply | Divide | Modulo: 5;
		}
	}

	function RenderOperator(op:SqlBinaryOperator):String {
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

	function RenderConst(value:SqlConstValue):String {
		return switch value {
			case SqlConstBool(v): v ? "1" : "0";
			case SqlConstInt(v): Std.string(v);
			case SqlConstFloat(v): Std.string(v);
			case SqlConstString(v): "'" + StringTools.replace(v, "'", "''") + "'";
			case SqlConstNull: "NULL";
		}
	}
}
