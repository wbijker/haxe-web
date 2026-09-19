package codequery.sqldrivers;

import codequery.sqlexpressions.AggregateSqlExpression;
import codequery.sqlexpressions.AllColumnsSqlExpression;
import codequery.sqlexpressions.BetweenSqlExpression;
import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.CaseSqlExpression;
import codequery.sqlexpressions.InSqlExpression;
import codequery.sqlexpressions.IsDistinctFromSqlExpression;
import codequery.sqlexpressions.NotSqlExpression;
import codequery.sqlexpressions.SqlFunctionExpression;
import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpressionVisitor;
import codequery.sqlexpressions.QuantifiedComparisonSqlExpression;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.ScalarSubquerySqlExpression;
import codequery.sqlexpressions.SqlCastExpression;
import codequery.sqlexpressions.SqlExpressionWalker;
import codequery.sqlexpressions.SqlParameterExpression;
import codequery.sqlexpressions.SqlType;
import codequery.sqlexpressions.WindowDefinition;
import codequery.sqlexpressions.WindowFrame;
import codequery.sqlexpressions.WindowFunctionExpression;
import codequery.sqlexpressions.DeleteExpression;
import codequery.sqlexpressions.ISqlStatement;
import codequery.sqlexpressions.InsertExpression;
import codequery.sqlexpressions.UpdateExpression;
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
class SqlDriver implements ISqlExpressionVisitor<String> {
	/**
		The statement being rendered, in the order a lambda's parameters bind to its sources. A
		generated column names its source by position, so rendering one is a lookup here.
	**/
	var sources:Array<ISqlSource> = [];

	/** The values of the statement being rendered, in the order their placeholders were numbered. */
	var parameters:Array<SqlConstValue> = [];

	/** What was sent beside the last statement rendered. */
	public var Parameters(default, null):Array<SqlConstValue> = [];

	public function new() {}

	/**
		Renders whichever statement it is given. C# tells them apart by overloading; Haxe has no
		overloading, so the statement says which kind it is and this asks.
	**/
	public function ToSql(statement:ISqlStatement):String {
		// Each statement collects its own values; a placeholder is numbered by where it lands.
		parameters = [];
		final sql = Render(statement);
		Parameters = parameters;
		return sql;
	}

	function Render(statement:ISqlStatement):String {
		final select = Std.downcast(cast statement, SelectExpression);
		if (select != null) {
			return ToSelectSql(select);
		}

		final update = Std.downcast(cast statement, UpdateExpression);
		if (update != null) {
			return Against(update.AllSources(), () -> UpdateSql(update));
		}

		final delete = Std.downcast(cast statement, DeleteExpression);
		if (delete != null) {
			return Against(delete.AllSources(), () -> DeleteSql(delete));
		}

		final insert = Std.downcast(cast statement, InsertExpression);
		if (insert != null) {
			return Against(insert.AllSources(), () -> InsertSql(insert));
		}

		throw 'Cannot render ${Type.getClassName(Type.getClass(statement))}';
	}

	/** Each statement renders against its own sources; whatever was in scope is restored after. */
	function Against(statementSources:Array<ISqlSource>, render:Void->String):String {
		final outer = sources;
		sources = statementSources;
		final sql = render();
		sources = outer;
		return sql;
	}

	function UpdateSql(update:UpdateExpression):String {
		if (update.Assignments.length == 0) {
			throw "An update sets something";
		}

		// The columns being assigned are the target's own, so they are named without its alias.
		final assignments = update.Assignments
			.map(a -> '${a.Column.ColumnName} = ${RenderExpression(a.Value)}')
			.join(", ");

		var sql = 'UPDATE ${Source(update.Target)} SET $assignments';
		if (update.FromSources.length > 0) {
			sql += ' FROM ${update.FromSources.map(Source).join(", ")}';
		}
		if (update.Where != null) {
			sql += ' WHERE ${RenderExpression(update.Where)}';
		}
		return sql + Returning(update.Returning);
	}

	function DeleteSql(delete:DeleteExpression):String {
		var sql = 'DELETE FROM ${Source(delete.Target)}';
		if (delete.FromSources.length > 0) {
			sql += ' USING ${delete.FromSources.map(Source).join(", ")}';
		}
		if (delete.Where != null) {
			sql += ' WHERE ${RenderExpression(delete.Where)}';
		}
		return sql + Returning(delete.Returning);
	}

	function InsertSql(insert:InsertExpression):String {
		final target = Std.downcast(cast insert.Target, TableSqlSource);
		if (target == null) {
			throw "Rows are inserted into a table";
		}

		final columns = insert.Columns.map(column -> column.ColumnName).join(", ");
		var sql = 'INSERT INTO ${target.Table} ($columns)';

		if (insert.FromSelect != null) {
			sql += ' ${ToSql(insert.FromSelect)}';
		} else {
			final rows = insert.Values.map(row -> '(${row.map(RenderExpression).join(", ")})').join(", ");
			sql += ' VALUES $rows';
		}
		return sql + Returning(insert.Returning);
	}

	function Returning(returning:Array<ISqlExpression>):String {
		return returning.length == 0 ? "" : ' RETURNING ${returning.map(RenderExpression).join(", ")}';
	}

	function ToSelectSql(expression:SelectExpression):String {
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
			final keys = expression.GroupBy.map(RenderExpression).join(", ");
			sql += switch expression.Grouping {
				case None: ' GROUP BY $keys';
				case Rollup: ' GROUP BY ROLLUP ($keys)';
				case Cube: ' GROUP BY CUBE ($keys)';
			}
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

		// A set operation joins two whole statements, so it comes after everything either says.
		for (union in expression.Unions) {
			final keyword = switch union.Type {
				case Union: "UNION";
				case UnionAll: "UNION ALL";
				case Intersect: "INTERSECT";
				case IntersectAll: "INTERSECT ALL";
				case Except: "EXCEPT";
				case ExceptAll: "EXCEPT ALL";
			}
			sql += ' $keyword ${Against(union.Query.AllSources(), () -> Statement(union.Query))}';
		}
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

	/** Every expression goes through the visitor, so a kind nobody handles will not compile. */
	public function RenderExpression(e:ISqlExpression):String {
		return SqlExpressionWalker.Visit(e, this);
	}

	public function OnColumn(e:ColumnSqlExpression):String {
		return '${AliasOf(e.Source)}.${e.ColumnName}';
	}

	public function OnAllColumns(e:AllColumnsSqlExpression):String {
		return '${AliasOf(e.Source)}.*';
	}

	public function OnConst(e:ConstSqlExpression):String {
		return RenderConst(e.Value);
	}

	public function OnParameter(e:SqlParameterExpression):String {
		parameters.push(e.Value);
		e.Ordinal = parameters.length;
		return '$$${e.Ordinal}';
	}

	public function OnBinary(e:BinarySqlExpression):String {
		final nullTest = NullTest(e);
		return nullTest != null
			? nullTest
			: '${Operand(e, e.Left)} ${RenderOperator(e.Operator)} ${Operand(e, e.Right)}';
	}

	public function OnNot(e:NotSqlExpression):String {
		return 'NOT (${RenderExpression(e.Operand)})';
	}

	public function OnIn(e:InSqlExpression):String {
		final keyword = e.Negate ? "NOT IN" : "IN";
		// Not correlated: the subquery stands on its own sources, so the outer ones are out of
		// scope inside it — unlike EXISTS, whose whole point is to reach them.
		final of = e.Subquery != null
			? Against(e.Subquery.AllSources(), () -> Statement(e.Subquery))
			: e.Values.map(RenderExpression).join(", ");
		return '${RenderExpression(e.Value)} $keyword ($of)';
	}

	public function OnBetween(e:BetweenSqlExpression):String {
		final keyword = e.Negate ? "NOT BETWEEN" : "BETWEEN";
		return '${RenderExpression(e.Value)} $keyword ${RenderExpression(e.Lower)} AND ${RenderExpression(e.Upper)}';
	}

	public function OnIsDistinctFrom(e:IsDistinctFromSqlExpression):String {
		final keyword = e.Negate ? "IS NOT DISTINCT FROM" : "IS DISTINCT FROM";
		return '${RenderExpression(e.Left)} $keyword ${RenderExpression(e.Right)}';
	}

	public function OnCase(e:CaseSqlExpression):String {
		var sql = "CASE";
		for (branch in e.Branches) {
			sql += ' WHEN ${RenderExpression(branch.When)} THEN ${RenderExpression(branch.Then)}';
		}
		if (e.Otherwise != null) {
			sql += ' ELSE ${RenderExpression(e.Otherwise)}';
		}
		return sql + " END";
	}

	public function OnFunction(e:SqlFunctionExpression):String {
		final arguments = e.Arguments.map(RenderExpression);
		return e.Infix ? arguments.join(' ${e.Name} ') : '${e.Name}(${arguments.join(", ")})';
	}

	public function OnCast(e:SqlCastExpression):String {
		return 'CAST(${RenderExpression(e.Value)} AS ${RenderType(e.Type)})';
	}

	public function OnRaw(e:RawSqlExpression):String {
		return e.Sql;
	}

	public function OnAggregate(e:AggregateSqlExpression):String {
		return RenderAggregate(e);
	}

	public function OnProjection(e:ProjectionSqlExpression):String {
		return e.Members.map(member -> '${RenderExpression(member.Expression)} AS ${member.Name}').join(", ");
	}

	public function OnExists(e:ExistsSqlExpression):String {
		return '${e.Negate ? "NOT EXISTS" : "EXISTS"} (${Correlated(e.Subquery)})';
	}

	public function OnScalarSubquery(e:ScalarSubquerySqlExpression):String {
		return e.Correlated
			? '(${Correlated(e.Subquery)})'
			: '(${Against(e.Subquery.AllSources(), () -> Statement(e.Subquery))})';
	}

	public function OnQuantified(e:QuantifiedComparisonSqlExpression):String {
		final quantifier = switch e.Quantifier {
			case Any: "ANY";
			case All: "ALL";
		}
		final of = Against(e.Subquery.AllSources(), () -> Statement(e.Subquery));
		return '${RenderExpression(e.Value)} ${RenderOperator(e.Operator)} $quantifier ($of)';
	}

	public function OnWindowFunction(e:WindowFunctionExpression):String {
		final name = switch e.Function {
			case RowNumber: "ROW_NUMBER";
			case Rank: "RANK";
			case DenseRank: "DENSE_RANK";
			case Lead: "LEAD";
			case Lag: "LAG";
			case FirstValue: "FIRST_VALUE";
			case LastValue: "LAST_VALUE";
		}
		// A window function only means anything over a window, so it always has one.
		final over = e.Window != null ? e.Window.Name : RenderOver(e.Over);
		return '$name(${e.Arguments.map(RenderExpression).join(", ")}) OVER $over';
	}

	public function OnOrderBy(e:OrderByExpression):String {
		return RenderOrderBy(e);
	}

	/** A window written out where it is used, rather than named on the statement. */
	function RenderOver(over:WindowDefinition):String {
		final parts = [];
		if (over.PartitionBy.length > 0) {
			parts.push('PARTITION BY ${over.PartitionBy.map(RenderExpression).join(", ")}');
		}
		if (over.OrderBy.length > 0) {
			parts.push('ORDER BY ${over.OrderBy.map(RenderOrderBy).join(", ")}');
		}
		if (over.Frame != null) {
			parts.push(RenderFrame(over.Frame));
		}
		return '(${parts.join(" ")})';
	}

	function RenderFrame(frame:WindowFrame):String {
		final kind = switch frame.Kind {
			case Rows: "ROWS";
			case Range: "RANGE";
		}
		return '$kind BETWEEN ${RenderBound(frame.Start)} AND ${RenderBound(frame.End)}';
	}

	function RenderBound(bound:codequery.sqlexpressions.WindowBound):String {
		return switch bound {
			case UnboundedPreceding: "UNBOUNDED PRECEDING";
			case Preceding(rows): '$rows PRECEDING';
			case CurrentRow: "CURRENT ROW";
			case Following(rows): '$rows FOLLOWING';
			case UnboundedFollowing: "UNBOUNDED FOLLOWING";
		}
	}

	function RenderType(type:SqlType):String {
		return switch type {
			case SqlInt: "INTEGER";
			case SqlBigInt: "BIGINT";
			case SqlFloat: "DOUBLE PRECISION";
			case SqlDecimal(precision, scale): 'DECIMAL($precision, $scale)';
			case SqlBool: "BOOLEAN";
			case SqlText: "TEXT";
			case SqlVarChar(length): 'VARCHAR($length)';
			case SqlDate: "DATE";
			case SqlTimestamp: "TIMESTAMP";
			case SqlUnknown: throw "A cast needs a type to cast to";
		}
	}

	/**
		A subquery that can name the outer statement's rows, so its sources are added to what is in
		scope rather than replacing it.
	**/
	function Correlated(subquery:SelectExpression):String {
		final outer = sources;
		sources = sources.concat(subquery.AllSources());
		final sql = Statement(subquery);
		sources = outer;
		return sql;
	}

	function RenderAggregate(aggregate:AggregateSqlExpression):String {
		final name = switch aggregate.Type {
			case Count: "COUNT";
			case Sum: "SUM";
			case Avg: "AVG";
			case Min: "MIN";
			case Max: "MAX";
		}
		if (aggregate.Distinct && aggregate.Argument == null) {
			throw "DISTINCT needs something to be distinct about, and this aggregate counts rows";
		}
		final distinct = aggregate.Distinct ? "DISTINCT " : "";
		// COUNT with nothing to count counts rows.
		final argument = aggregate.Argument == null ? "*" : RenderExpression(aggregate.Argument);
		var sql = '$name($distinct$argument)';

		if (aggregate.Filter != null) {
			sql += ' FILTER (WHERE ${RenderExpression(aggregate.Filter)})';
		}
		if (aggregate.Window != null) {
			sql += ' OVER ${aggregate.Window.Name}';
		} else if (aggregate.Over != null) {
			sql += ' OVER ${RenderOver(aggregate.Over)}';
		}
		return sql;
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
			case SqlConstDate(v): "'" + DateTools.format(v, "%Y-%m-%d %H:%M:%S") + "'";
			case SqlConstNull: "NULL";
		}
	}
}
