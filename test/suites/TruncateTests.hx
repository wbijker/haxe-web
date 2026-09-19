package suites;

import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`TruncateTests.cs`: TRUNCATE — a common statement. The C# renders it per driver, SQLite
	falling back to DELETE FROM; the port has the one dialect, so that is the one rendered.
**/
class TruncateTests extends TestCase {
	function testTruncate_RendersPerDriver() {
		Assert.equals("TRUNCATE TABLE books", new SqlTranslator().BuildTruncateSql("books", null));
		Assert.equals("TRUNCATE TABLE shop.books", new SqlTranslator().BuildTruncateSql("books", "shop"));
	}
}
