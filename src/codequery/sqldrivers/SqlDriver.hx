package codequery.sqldrivers;

import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.NullsOrdering;
import codequery.sqlexpressions.OrderByExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SqlBinaryOperator;
import codequery.sqlexpressions.SqlConstValue;
import codequery.sqlexpressions.TableSqlSource;

/**
	Renders a statement as SQL. The C# original splits this into an `ISqlTranslator` that renders
	and an `ISqlDriver` that also knows where to send the result; only the rendering half is here,
	and only what a SELECT with a WHERE needs of it.
**/
class SqlDriver {
	public function new() {}

	public function ToSql(expression:SelectExpression):String {
		final source = Std.downcast(cast expression.Source, TableSqlSource);
		if (source == null) {
			throw "Only a table source is supported so far";
		}

		// A table that carries its own name as its alias is just the table.
		final from = source.Alias == source.Table.Name
			? '${source.Table}'
			: '${source.Table} AS ${source.Alias}';

		var sql = 'SELECT${Distinct(expression)} * FROM $from';
		if (expression.Where != null) {
			sql += ' WHERE ${RenderExpression(expression.Where)}';
		}
		if (expression.OrderBy.length > 0) {
			sql += ' ORDER BY ${expression.OrderBy.map(RenderOrderBy).join(", ")}';
		}
		sql += RowLimit(expression);
		return sql;
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
		thing for the three node kinds that exist so far.
	**/
	function RenderExpression(e:ISqlExpression):String {
		final column = Std.downcast(cast e, ColumnSqlExpression);
		if (column != null) {
			return '${column.Source.Alias}.${column.ColumnName}';
		}

		final constant = Std.downcast(cast e, ConstSqlExpression);
		if (constant != null) {
			return RenderConst(constant.Value);
		}

		final binary = Std.downcast(cast e, BinarySqlExpression);
		if (binary != null) {
			return '${Operand(binary, binary.Left)} ${RenderOperator(binary.Operator)} ${Operand(binary, binary.Right)}';
		}

		throw 'Cannot render ${Type.getClassName(Type.getClass(e))}';
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
