package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("user")
class FlatUser {
	public var id:Int = 0;
	public var email:String = "";
	public var roleId:Null<Int>;

	public function new() {}
}

@tableName("user_role")
class FlatUserRole {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

typedef FlatRow = {
	email:String,
	?roleName:String,
}

/**
	`ProjectedQueryFlatteningTests.cs`: a projection makes a query whose source is the query it
	projected from, and DISTINCT, LIMIT and OFFSET fold into it rather than wrapping it — those
	three name no columns, so they mean the same thing inside the query as around it. The C#
	expects PostgreSQL's quoted spelling; the port renders one plain dialect, and it is the shape of
	the statement that is asserted.
**/
class ProjectedQueryFlatteningTests extends TestCase {
	static function Sql(query:codequery.sqlexpressions.SelectExpression):String {
		return new SqlTranslator().ToSql(query);
	}

	// --- One row off a projection ---

	function testALimitAfterAProjection_IsOneStatement() {
		final sql = Sql(Query.select(FlatUser)
			.Where(u -> u.id == 274)
			.Select(u -> ({email: u.email} : FlatRow))
			.Limit(1)
			.ToExpression());

		Assert.doesNotContain("FROM (", sql);
		Assert.equals("SELECT t0.email AS email FROM user AS t0 WHERE t0.id = 274 LIMIT 1", sql);
	}

	function testALimitAfterAJoinedProjection_IsOneStatement() {
		final sql = Sql(Query.select(FlatUser)
			.LeftJoin(Query.select(FlatUserRole), (u, r) -> r.id == u.roleId)
			.Where((u, r) -> u.id == 274)
			.Select((u, r) -> ({email: u.email, roleName: u.roleId == null ? null : r.name} : FlatRow))
			.Limit(1)
			.ToExpression());

		Assert.doesNotContain("FROM (", sql);
		Assert.contains("LEFT JOIN user_role AS t1", sql);
		Assert.endsWith("LIMIT 1", sql);
	}

	function testALimitAfterAScalarProjection_IsOneStatement() {
		final sql = Sql(Query.select(FlatUser)
			.Where(u -> u.id == 274)
			.Select(u -> u.roleId)
			.Limit(1)
			.ToExpression());

		Assert.doesNotContain("FROM (", sql);
		Assert.endsWith("LIMIT 1", sql);
	}

	// --- Distinct off a projection ---

	function testDistinctAfterAProjection_IsOneStatement() {
		final sql = Sql(Query.select(FlatUser)
			.Where(u -> u.id == 274)
			.Select(u -> u.roleId)
			.Distinct()
			.ToExpression());

		Assert.doesNotContain("FROM (", sql);
		Assert.startsWith("SELECT DISTINCT t0.roleId", sql);
	}

	function testDistinctAndALimitTogether_AreBothOnTheOneStatement() {
		final sql = Sql(Query.select(FlatUser)
			.Select(u -> u.roleId)
			.Distinct()
			.Limit(5)
			.ToExpression());

		Assert.doesNotContain("FROM (", sql);
		Assert.startsWith("SELECT DISTINCT", sql);
		Assert.endsWith("LIMIT 5", sql);
	}

	// --- Where folding would change what the query means ---

	function testALimitOverALimit_KeepsItsSubquery() {
		// Projected again, so the limited query really is the source of a second one — rather than the
		// two limits being two writes to the same field.
		final firstTen = Query.select(FlatUser).Select(u -> ({email: u.email} : FlatRow)).Limit(10);

		final sql = Sql(firstTen.Select(r -> ({email: r.email} : FlatRow)).Limit(1).ToExpression());

		Assert.contains("FROM (", sql);
		Assert.contains("LIMIT 10", sql);
		Assert.endsWith("LIMIT 1", sql);
	}

	function testDistinctOverAUnion_KeepsItsSubquery() {
		final sql = Sql(Query.select(FlatUser).Select(u -> u.roleId)
			.Union(Query.select(FlatUser).Select(u -> u.roleId))
			.Distinct()
			.ToExpression());

		Assert.contains("FROM (", sql);
	}

	function testAFilterAfterAProjection_KeepsItsSubquery() {
		final sql = Sql(Query.select(FlatUser)
			.Select(u -> ({email: u.email} : FlatRow))
			.Where(r -> r.email == "a@b.c")
			.Limit(1)
			.ToExpression());

		Assert.contains("FROM (", sql);
	}
}
