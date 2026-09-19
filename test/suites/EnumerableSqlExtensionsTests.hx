package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("widgets")
class EnumWidget {
	public var id:Int = 0;

	@columnNullable(false)
	public var status:String = "";

	/** Nullable: a widget need not have an owner. */
	public var ownerId:Null<Int>;

	public function new() {}
}

@tableName("flagged")
class EnumFlagged {
	public var id:Int = 0;
	public var widgetId:Int = 0;

	public function new() {}
}

/**
	`EnumerableSqlExtensionsTests.cs`: is this value one of those? C#'s `x.In(set)` is `Sql.isIn(x, set)`
	here; the set is a collection the query holds, values written at the call site, or — as
	`Sql.inQuery` — what another query selects, and reads the same way in each.

	The C# helper `Where(where)` takes the predicate as a value; a Haxe predicate is read where it
	is written, so each test writes the query out.
**/
class EnumerableSqlExtensionsTests extends TestCase {
	// --- A collection the query holds ---------------------------------------------------------------

	function testACollectionBecomesAnInList() {
		final ids = [1, 2, 3];

		final where = Query.select(EnumWidget).Where(w -> Sql.isIn(w.id, ids)).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		where.inValues([1, 2, 3]).Value.column("id");
	}

	function testAndItsNegation() {
		final ids = [1, 2];

		final where = Query.select(EnumWidget).Where(w -> Sql.notIn(w.id, ids)).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		final membership = where.isIn(true);
		membership.Value.column("id");
		Assert.equals([1, 2], membership.Values.map(SqlAssert.valueOf));
	}

	/** Any collection, not just an array: what matters is that the query holds it. */
	function testAnySortOfCollection() {
		final set = new haxe.ds.List<String>();
		set.add("open");

		final where = Query.select(EnumWidget).Where(w -> Sql.isIn(w.status, set)).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		where.inValues(["open"]).Value.column("status");
	}

	// --- Values written at the call site ------------------------------------------------------------

	function testValuesWrittenHereBecomeTheList() {
		final where = Query.select(EnumWidget).Where(w -> Sql.isIn(w.status, ["open", "hold"])).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		where.inValues(["open", "hold"]).Value.column("status");

		final negated = Query.select(EnumWidget).Where(w -> Sql.notIn(w.status, ["done"])).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		Assert.isTrue(negated.isIn(true).Negate);
	}

	// --- What another query selects -----------------------------------------------------------------

	function testAnotherQueryBecomesASubquery() {
		final flagged = Query.select(EnumFlagged).Select(f -> f.widgetId);

		final where = Query.select(EnumWidget).Where(w -> Sql.inQuery(w.id, flagged)).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		final subquery = where.inSubquery();
		Assert.equals("flagged", subquery.selectTableName());
		subquery.selection().column("widgetId");

		final negated = Query.select(EnumWidget).Where(w -> Sql.notInQuery(w.id, flagged)).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		Assert.equals("flagged", negated.inSubquery(true).selectTableName());
	}

	// --- A value that may be absent -----------------------------------------------------------------

	function testANullableValueTestsTheSameWay() {
		final ids = [4, 5];

		final where = Query.select(EnumWidget).Where(w -> Sql.isIn(w.ownerId, ids)).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		where.inValues([4, 5]).Value.column("ownerId");
	}

	/**
		A row with no owner is not one of the owners asked about, so it is kept — which is what the
		language says and what a bare NOT IN does not.
	**/
	function testAndItsNegationKeepsTheAbsentRows() {
		final ids = [4, 5];

		final where = Query.select(EnumWidget).Where(w -> Sql.notIn(w.ownerId, ids)).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		final or = where.binary(Or);

		or.Left.isIn(true).Value.column("ownerId");

		final isNull = or.Right.binary(Equal);
		isNull.Left.column("ownerId");
		isNull.Right.nullConst();
	}

	/** A value that cannot be absent has nothing to keep, and stays plain. */
	function testAValueThatCannotBeAbsentStaysPlain() {
		final where = Query.select(EnumWidget).Where(w -> Sql.notIn(w.status, ["done"])).Select(w -> {id: w.id})
			.ToExpression().whereClause();
		final membership = where.isIn(true);

		membership.Value.column("status");
		Assert.equals(["done"], membership.Values.map(SqlAssert.valueOf));
	}

	// --- The edges ----------------------------------------------------------------------------------

	/** Nothing is in an empty set, and everything is not — the list is simply empty. */
	function testAnEmptySetIsAnswered() {
		final none:Array<Int> = [];

		final inNone = Query.select(EnumWidget).Where(w -> Sql.isIn(w.id, none)).Select(w -> {id: w.id})
			.ToExpression().whereClause().isIn();
		inNone.Value.column("id");
		Assert.empty(inNone.Values);

		final notInNone = Query.select(EnumWidget).Where(w -> Sql.notIn(w.id, none)).Select(w -> {id: w.id})
			.ToExpression().whereClause().isIn(true);
		Assert.empty(notInNone.Values);
	}

	function testASetThatIsNotThereSaysSo() {
		var missing:Array<Int> = null;

		final error = Assert.throwsMessage(() -> Query.select(EnumWidget).Where(w -> Sql.isIn(w.id, missing)));
		Assert.contains("must be a collection that is there", error);
	}

	/** A set read off the row is the driver's business, and says which one it is. */
	function testASetReadFromTheRowSaysSo() {
		final error = Assert.throwsMessage(() -> Query.select(EnumWidget).Where(w -> Sql.isIn(w.id, [w.id, w.id + 1])));

		Assert.contains("read from the row", error);
	}

	function testOutsideAQueryItSaysSo() {
		Assert.skip("Sql is an extern class: calling it outside a lambda is an uncatchable eval error, not an exception");
	}

	// --- Every dialect ------------------------------------------------------------------------------

	function testEachDialectWritesItsOwn() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port (nor SQLite's spelling)");
	}

	// --- The values are data ------------------------------------------------------------------------

	/**
		Sent to the database the values are bound, one parameter each, because they came from a
		variable rather than from the text of the query.
	**/
	function testTheValuesAreBoundWhenTheStatementIsSent() {
		final ids = [7, 8];
		final translator = new SqlTranslator();
		final sql = translator.ToSql(
			Query.select(EnumWidget).Where(w -> Sql.inBound(w.id, ids)).Select(w -> {id: w.id}).ToExpression());

		Assert.contains("IN ($1, $2)", sql);
		Assert.equals([7, 8], translator.Parameters.map(SqlAssert.ValueOfConst));
	}

	// --- Against a database -------------------------------------------------------------------------

	function testItFindsTheRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
