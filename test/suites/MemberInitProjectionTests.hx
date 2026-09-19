package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** C#'s `BookRow` result class; a Haxe projection into a named shape is a structure typed as one. */
typedef BookRow = {
	bookId:Int,
	label:String,
}

/** `MemberInitProjectionTests.cs`: projections into named result types, `Select(b -> ({…} : BookRow))`. */
class MemberInitProjectionTests extends TestCase {
	function testSelect_MemberInit_ProjectsBoundMembersWithTheirNames() {
		final exp = Query.select(Book)
			.Select(b -> ({bookId: b.id, label: b.title} : BookRow))
			.ToExpression();

		Assert.equals(["bookId", "label"], exp.memberNames());
		exp.selectionOf("bookId").column("id");
		exp.selectionOf("label").column("title");
	}

	function testSelect_MemberInit_RendersMemberNamesAsAliases() {
		final query = Query.select(Book)
			.Select(b -> ({bookId: b.id, label: b.title} : BookRow));

		final sql = new SqlTranslator().ToSql(query.ToExpression());

		Assert.contains("AS bookId", sql);
		Assert.contains("AS label", sql);
	}
}
