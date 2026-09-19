package codequery.testing;

import codequery.migrations.RawStatement;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;

/**
	The C# tests' `SqlAssert` and the `*Access` helpers, as one set of statics.

	Where C# reaches these as extension methods, a Haxe test reaches them by `using
	codequery.testing.SqlAssert;`, which reads the same at the call site.
**/
class SqlAssert {
	// ---- expressions ---------------------------------------------------------------------------

	public static function expression<T:{}>(e:ISqlExpression, cls:Class<T>):T {
		Assert.notNull(e, "Expected an expression, got null");
		return Assert.isType(e, cls);
	}

	public static function column(e:ISqlExpression, ?name:String, ?alias:String):ColumnSqlExpression {
		final c = expression(e, ColumnSqlExpression);
		if (name != null) {
			Assert.equals(name, c.ColumnName, "column name");
		}
		if (alias != null) {
			Assert.equals(alias, c.Source.Alias, "column source alias");
		}
		return c;
	}

	public static function constant(e:ISqlExpression, ?expected:Dynamic):ConstSqlExpression {
		final c = expression(e, ConstSqlExpression);
		if (expected != null) {
			Assert.equals(expected, constValue(c), "constant value");
		}
		return c;
	}

	public static function nullConst(e:ISqlExpression):ConstSqlExpression {
		final c = expression(e, ConstSqlExpression);
		Assert.isTrue(c.Value.match(SqlConstNull), "Expected a null constant");
		return c;
	}

	/** The value a constant carries, as a plain value a test can compare. */
	public static function constValue(e:ISqlExpression):Dynamic {
		return ValueOfConst(expression(e, ConstSqlExpression).Value);
	}

	public static function ValueOfConst(value:SqlConstValue):Dynamic {
		return switch value {
			case SqlConstBool(v): v;
			case SqlConstInt(v): v;
			case SqlConstFloat(v): v;
			case SqlConstString(v): v;
			case SqlConstDate(v): v;
			case SqlConstNull: null;
		}
	}

	public static function bound(e:ISqlExpression, ?expected:Dynamic):SqlParameterExpression {
		final p = expression(e, SqlParameterExpression);
		if (expected != null) {
			Assert.equals(expected, ValueOfConst(p.Value), "parameter value");
		}
		return p;
	}

	/** A constant or a parameter, whichever carries the value; the tests do not care which. */
	public static function value(e:ISqlExpression, expected:Dynamic):ISqlExpression {
		Assert.notNull(e);
		Assert.equals(expected, valueOf(e), "value");
		return e;
	}

	public static function valueOf(e:ISqlExpression):Dynamic {
		final c = Std.downcast(cast e, ConstSqlExpression);
		if (c != null) {
			return ValueOfConst(c.Value);
		}
		final p = Std.downcast(cast e, SqlParameterExpression);
		if (p != null) {
			return ValueOfConst(p.Value);
		}
		return Assert.fail('${Type.getClassName(Type.getClass(e))} does not carry a value');
	}

	public static function binary(e:ISqlExpression, ?op:SqlBinaryOperator):BinarySqlExpression {
		final b = expression(e, BinarySqlExpression);
		if (op != null) {
			Assert.equals(op, b.Operator, "operator");
		}
		return b;
	}

	public static function comparison(e:ISqlExpression, columnName:String, op:SqlBinaryOperator,
			expected:Dynamic):BinarySqlExpression {
		final b = binary(e, op);
		column(b.Left, columnName);
		value(b.Right, expected);
		return b;
	}

	public static function columnComparison(e:ISqlExpression, left:String, op:SqlBinaryOperator,
			right:String):BinarySqlExpression {
		final b = binary(e, op);
		column(b.Left, left);
		column(b.Right, right);
		return b;
	}

	public static function not(e:ISqlExpression):NotSqlExpression {
		return expression(e, NotSqlExpression);
	}

	public static function between(e:ISqlExpression, negate:Bool = false):BetweenSqlExpression {
		final b = expression(e, BetweenSqlExpression);
		Assert.equals(negate, b.Negate, "negate");
		return b;
	}

	public static function isIn(e:ISqlExpression, negate:Bool = false):InSqlExpression {
		final i = expression(e, InSqlExpression);
		Assert.equals(negate, i.Negate, "negate");
		return i;
	}

	public static function inValues(e:ISqlExpression, values:Array<Dynamic>):InSqlExpression {
		final i = isIn(e);
		Assert.equals(values, i.Values.map(valueOf), "IN values");
		return i;
	}

	public static function inSubquery(e:ISqlExpression, negate:Bool = false):SelectExpression {
		final i = isIn(e, negate);
		Assert.notNull(i.Subquery, "Expected IN over a subquery");
		return i.Subquery;
	}

	public static function exists(e:ISqlExpression, negate:Bool = false):ExistsSqlExpression {
		final x = expression(e, ExistsSqlExpression);
		Assert.equals(negate, x.Negate, "negate");
		return x;
	}

	public static function quantified(e:ISqlExpression, op:SqlBinaryOperator, isAll:Bool):QuantifiedComparisonSqlExpression {
		final q = expression(e, QuantifiedComparisonSqlExpression);
		Assert.equals(op, q.Operator, "operator");
		Assert.equals(isAll, q.Quantifier.match(All), "quantifier");
		return q;
	}

	public static function aggregate(e:ISqlExpression, ?type:AggregateType):AggregateSqlExpression {
		final a = expression(e, AggregateSqlExpression);
		if (type != null) {
			Assert.equals(type, a.Type, "aggregate");
		}
		return a;
	}

	public static function windowFunction(e:ISqlExpression, ?fn:WindowFunction):WindowFunctionExpression {
		final w = expression(e, WindowFunctionExpression);
		if (fn != null) {
			Assert.equals(fn, w.Function, "window function");
		}
		return w;
	}

	public static function caseWhen(e:ISqlExpression):CaseSqlExpression {
		return expression(e, CaseSqlExpression);
	}

	public static function call(e:ISqlExpression, ?name:String):SqlFunctionExpression {
		final f = expression(e, SqlFunctionExpression);
		if (name != null) {
			Assert.equals(name, f.Name, "function");
		}
		return f;
	}

	public static function castTo(e:ISqlExpression):SqlCastExpression {
		return expression(e, SqlCastExpression);
	}

	public static function raw(e:ISqlExpression, ?sql:String):RawSqlExpression {
		final r = expression(e, RawSqlExpression);
		if (sql != null) {
			Assert.equals(sql, r.Sql, "raw sql");
		}
		return r;
	}

	public static function scalar(e:ISqlExpression):SelectExpression {
		return expression(e, ScalarSubquerySqlExpression).Subquery;
	}

	public static function distinctFrom(e:ISqlExpression, negate:Bool = false):IsDistinctFromSqlExpression {
		final d = expression(e, IsDistinctFromSqlExpression);
		Assert.equals(negate, d.Negate, "negate");
		return d;
	}

	// ---- statement access: SELECT ------------------------------------------------------------

	public static function whereClause(select:SelectExpression):ISqlExpression {
		Assert.notNull(select.Where, "Expected a WHERE clause");
		return select.Where;
	}

	public static function whereBinary(select:SelectExpression, ?op:SqlBinaryOperator):BinarySqlExpression {
		return binary(whereClause(select), op);
	}

	public static function havingClause(select:SelectExpression):ISqlExpression {
		Assert.notNull(select.Having, "Expected a HAVING clause");
		return select.Having;
	}

	public static function havingBinary(select:SelectExpression, ?op:SqlBinaryOperator):BinarySqlExpression {
		return binary(havingClause(select), op);
	}

	public static function selection(select:SelectExpression):ISqlExpression {
		Assert.notNull(select.Selection, "Expected a selection");
		return select.Selection;
	}

	public static function projection(select:SelectExpression, ?memberCount:Int):ProjectionSqlExpression {
		final p = expression(selection(select), ProjectionSqlExpression);
		if (memberCount != null) {
			Assert.equals(memberCount, p.Members.length, "projection member count");
		}
		return p;
	}

	public static function memberNames(select:SelectExpression):Array<String> {
		return projection(select).Members.map(m -> m.Name);
	}

	public static function member(select:SelectExpression, name:String):ProjectionMember {
		final p = projection(select);
		for (m in p.Members) {
			if (m.Name == name) {
				return m;
			}
		}
		return Assert.fail('The projection has no member "$name"; it has ${p.Members.map(m -> m.Name).join(", ")}');
	}

	public static function memberAt(select:SelectExpression, index:Int):ProjectionMember {
		final p = projection(select);
		Assert.inRange(index, 0, p.Members.length - 1);
		return p.Members[index];
	}

	public static function selectionOf(select:SelectExpression, name:String):ISqlExpression {
		return member(select, name).Expression;
	}

	public static function selectionAt(select:SelectExpression, index:Int):ISqlExpression {
		return memberAt(select, index).Expression;
	}

	public static function orderBy(select:SelectExpression, index:Int = 0):OrderByExpression {
		Assert.inRange(index, 0, select.OrderBy.length - 1);
		return select.OrderBy[index];
	}

	public static function groupBy(select:SelectExpression, index:Int = 0):ISqlExpression {
		Assert.inRange(index, 0, select.GroupBy.length - 1);
		return select.GroupBy[index];
	}

	public static function join(select:SelectExpression, index:Int = 0):JoinSqlExpression {
		Assert.inRange(index, 0, select.Joins.length - 1);
		return select.Joins[index];
	}

	public static function joinOfType(select:SelectExpression, type:JoinType, index:Int = 0):JoinSqlExpression {
		final ofType = select.Joins.filter(j -> Type.enumEq(j.Type, type));
		Assert.inRange(index, 0, ofType.length - 1);
		return ofType[index];
	}

	public static function joinOnBinary(select:SelectExpression, index:Int = 0):BinarySqlExpression {
		return binary(join(select, index).On);
	}

	public static function union(select:SelectExpression, index:Int = 0):UnionSqlExpression {
		Assert.inRange(index, 0, select.Unions.length - 1);
		return select.Unions[index];
	}

	public static function window(select:SelectExpression, name:String):NamedWindowSqlSource {
		for (w in select.Windows) {
			if (w.Name == name) {
				return w;
			}
		}
		return Assert.fail('No window named "$name"');
	}

	// ---- sources -----------------------------------------------------------------------------

	public static function asTable(source:ISqlSource):TableSqlSource {
		return Assert.isType(source, TableSqlSource);
	}

	public static function asQuery(source:ISqlSource):SelectExpression {
		return Assert.isType(source, QuerySqlSource).Query;
	}

	public static function tableName(source:ISqlSource):String {
		final t = Std.downcast(cast source, TableSqlSource);
		if (t != null) {
			return t.Table.Name;
		}
		final c = Std.downcast(cast source, CteSqlSource);
		if (c != null) {
			return c.Cte.Name;
		}
		return Assert.fail('${Type.getClassName(Type.getClass(source))} has no table name');
	}

	public static function tableSource(select:SelectExpression):TableSqlSource {
		return asTable(select.Source);
	}

	public static function selectTableName(select:SelectExpression):String {
		return tableName(select.Source);
	}

	public static function subquery(select:SelectExpression):SelectExpression {
		return asQuery(select.Source);
	}

	public static function joinedQuery(select:SelectExpression, index:Int = 0):SelectExpression {
		return asQuery(join(select, index).Source);
	}

	public static function joinedTableName(select:SelectExpression, index:Int = 0):String {
		return tableName(join(select, index).Source);
	}

	// ---- statement access: UPDATE / DELETE / INSERT -------------------------------------------

	public static function updateWhere(update:UpdateExpression):ISqlExpression {
		Assert.notNull(update.Where, "Expected a WHERE clause");
		return update.Where;
	}

	public static function updateWhereBinary(update:UpdateExpression):BinarySqlExpression {
		return binary(updateWhere(update));
	}

	public static function deleteWhere(delete:DeleteExpression):ISqlExpression {
		Assert.notNull(delete.Where, "Expected a WHERE clause");
		return delete.Where;
	}

	public static function deleteWhereBinary(delete:DeleteExpression):BinarySqlExpression {
		return binary(deleteWhere(delete));
	}

	public static function assignment(update:UpdateExpression, columnName:String):SetAssignment {
		for (a in update.Assignments) {
			if (a.Column.ColumnName == columnName) {
				return a;
			}
		}
		return Assert.fail('No assignment to "$columnName"; assigned: ${assignedColumns(update).join(", ")}');
	}

	public static function assignedValue(update:UpdateExpression, columnName:String):ISqlExpression {
		return assignment(update, columnName).Value;
	}

	public static function assignedColumns(update:UpdateExpression):Array<String> {
		return update.Assignments.map(a -> a.Column.ColumnName);
	}

	public static function insertColumns(insert:InsertExpression):Array<String> {
		return insert.Columns.map(c -> c.ColumnName);
	}

	public static function insertRow(insert:InsertExpression, index:Int = 0):Array<ISqlExpression> {
		Assert.inRange(index, 0, insert.Values.length - 1);
		return insert.Values[index];
	}

	public static function insertValue(insert:InsertExpression, columnName:String, index:Int = 0):ISqlExpression {
		final names = insertColumns(insert);
		final at = names.indexOf(columnName);
		if (at < 0) {
			Assert.fail('No column "$columnName" in the insert; it has ${names.join(", ")}');
		}
		return insertRow(insert, index)[at];
	}

	public static function insertSelect(insert:InsertExpression):SelectExpression {
		Assert.notNull(insert.FromSelect, "Expected INSERT ... SELECT");
		return insert.FromSelect;
	}
}
