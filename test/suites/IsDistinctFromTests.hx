package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.isdistinctfrom.Entities;

using codequery.testing.SqlAssert;

/**
	`IsDistinctFromTests.cs` — `DbFunctions.IsDistinctFrom` is `Sql.isDistinctFrom`, and `DbFunctions.Row`
	is `Sql.row`. The port renders one dialect, which says it directly as PostgreSQL does.
**/
class IsDistinctFromTests extends TestCase {
	/** The rendered WHERE clause, as the C# `Where` helper cuts it out. */
	static function where(statement:ISqlStatement):String {
		final sql = new SqlTranslator().ToSql(statement);
		return sql.substr(sql.indexOf("WHERE ") + 6);
	}

	// ---- what the query says -------------------------------------------------------------------------

	function testItComparesTheTwoValues() {
		final distinct = Query.select(Unit).Where(r -> Sql.isDistinctFrom(r.name, r.previousName)).ToExpression()
			.whereClause().distinctFrom();

		Assert.isFalse(Std.isOfType(distinct.Left, RowSqlExpression));
		distinct.Left.column("name");
		distinct.Right.column("previousName");
	}

	/** The row form the operator is worth having for: one comparison over three columns. */
	function testARowComparesEveryColumnAtOnce() {
		final distinct = Query.select(Unit).Where(r -> Sql.isDistinctFrom(
			Sql.row(r.name, r.sleeps, r.notes),
			Sql.row(r.previousName, r.previousSleeps, r.notes))).ToExpression()
			.whereClause().distinctFrom();

		final left = Assert.isType(distinct.Left, RowSqlExpression);
		final right = Assert.isType(distinct.Right, RowSqlExpression);
		Assert.count(3, left.Values);
		left.Values[0].column("name");
		left.Values[1].column("sleeps");
		left.Values[2].column("notes");
		right.Values[0].column("previousName");
		right.Values[1].column("previousSleeps");
		right.Values[2].column("notes");
	}

	/** A predicate like any other: it negates, and it takes values as well as columns. */
	function testItIsAPredicateLikeAnyOther() {
		final name = "cabin";

		final negated = Query.select(Unit).Where(r -> !Sql.isDistinctFrom(r.name, name)).ToExpression()
			.whereClause().not();
		final against = negated.Operand.distinctFrom();
		against.Left.column("name");
		against.Right.value("cabin");

		final and = Query.select(Unit)
			.Where(r -> r.name == "cabin" && Sql.isDistinctFrom(r.sleeps, r.previousSleeps)).ToExpression()
			.whereBinary(And);
		and.Right.distinctFrom();
	}

	/** Nullable columns are the point of it: a NULL on one side is a difference, not an unknown. */
	function testANullableColumnAgainstNull() {
		final distinct = Query.select(Unit).Where(r -> Sql.isDistinctFrom(r.notes, null)).ToExpression()
			.whereClause().distinctFrom();

		distinct.Left.column("notes");
		distinct.Right.nullConst();
	}

	// ---- how each dialect says it ----------------------------------------------------------------------

	function testPostgres_SaysItDirectly() {
		Assert.equals("t0.name IS DISTINCT FROM t0.previousName",
			where(Query.select(Unit).Where(r -> Sql.isDistinctFrom(r.name, r.previousName)).ToExpression()));
	}

	function testSqlite_UsesIsNot() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect (IS NOT spelling)");
	}

	function testMySql_NegatesTheNullSafeEquals() {
		final sql = new codequery.mysql.MySqlSqlTranslator()
			.ToSql(Query.select(Unit).Where(r -> Sql.isDistinctFrom(r.name, r.previousName)).ToExpression());
		Assert.equals("(NOT (t0.name <=> t0.previousName))", sql.substr(sql.indexOf("WHERE ") + 6));
	}

	function testSqlServer_UsesIntersect() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect (INTERSECT spelling)");
	}

	// ---- several values, compared as rows --------------------------------------------------------------

	function testPostgres_ComparesRowsAsRows() {
		Assert.equals(
			"(t0.name, t0.sleeps, t0.notes) IS DISTINCT FROM (t0.previousName, t0.previousSleeps, t0.notes)",
			where(Query.select(Unit).Where(r -> Sql.isDistinctFrom(
				Sql.row(r.name, r.sleeps, r.notes), Sql.row(r.previousName, r.previousSleeps, r.notes))).ToExpression()));
	}

	function testTheOthers_CompareColumnByColumn() {
		Assert.skip("SqliteSqlDriver/MySqlSqlDriver: no SQLite or MySQL dialect (column-by-column spelling)");
	}

	function testSqlServer_IntersectsTheWholeRow() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect (INTERSECT spelling)");
	}
}
