package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `ToStringCastTests.cs` — `Std.string(x)` on a column, C#'s `x.ToString()`, is `CAST(x AS text)`. */
class ToStringCastTests extends TestCase {
	function testToString_OnNumericColumn_ConvertsToCastToString() {
		final exp = Query.select(Book)
			.Select(b -> Std.string(b.publishedYear))
			.ToExpression();

		final converted = exp.selectionAt(0).castTo();
		Assert.equals(SqlType.SqlText, converted.Type);
		converted.Value.column("publishedYear");
	}

	function testToString_InPredicate_RendersCast() {
		final sql = new SqlTranslator().ToSql(Query.select(Book)
			.Where(b -> Sql.ilike(Std.string(b.publishedYear), "%20%"))
			.ToExpression());

		Assert.contains("ILIKE", sql);
		Assert.contains("publishedYear", sql);
	}
}
