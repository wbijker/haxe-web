package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("widgets")
class DeletedWidget {
	public var id:Int = 0;
	public var name:String = "";
	public var size:Int = 0;

	public function new() {}
}

/**
	`DeleteExecutionTests.cs`: a filtered DELETE, run rather than rendered.

	The C# runs these because the rendering once passed and the statement still failed against a
	real database — the WHERE named an alias the DELETE never declared. What can be checked here is
	that the statement declares the alias its WHERE names; how many rows go needs a database.
**/
class DeleteExecutionTests extends TestCase {
	static final NoDatabase = "needs a database: eval has none (PHP runtime only)";

	static final widgets:DbTable<DeletedWidget> = Query.table(DeletedWidget);

	function testDeletes_only_the_matching_rows() {
		final sql = new SqlTranslator().ToSql(widgets.Delete().Where(w -> w.name == "drop").ToExpression());

		Assert.equals("DELETE FROM widgets AS t0 WHERE t0.name = 'drop'", sql);
		Assert.skip(NoDatabase);
	}

	function testDeletes_on_a_compound_predicate() {
		final sql = new SqlTranslator().ToSql(widgets.Delete().Where(w -> w.name == "drop" && w.size > 2).ToExpression());

		Assert.equals("DELETE FROM widgets AS t0 WHERE t0.name = 'drop' AND t0.size > 2", sql);
		Assert.skip(NoDatabase);
	}

	function testDeletes_everything_when_unfiltered() {
		Assert.equals("DELETE FROM widgets AS t0", new SqlTranslator().ToSql(widgets.Delete().ToExpression()));
		Assert.skip(NoDatabase);
	}
}
