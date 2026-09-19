package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;
using codequery.testing.SourceAccess;

@tableName("writers")
class GenericWriter {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

@tableName("novels")
class GenericNovel {
	public var id:Int = 0;
	public var writerId:Int = 0;

	public function new() {}

	/** Who wrote it — the relationship, said once. */
	public static function WithWriter():(GenericNovel, GenericWriter) -> Bool {
		return (n, w) -> w.id == n.writerId;
	}
}

class GenericEditor {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

class GenericArticle {
	public var id:Int = 0;
	public var editorId:Int = 0;

	public function new() {}

	public static function WithEditor():(GenericArticle, GenericEditor) -> Bool {
		return (a, e) -> e.id == a.editorId;
	}
}

/**
	`GenericJoinTests.cs` — the relationship join: `query.InnerJoin(Novel.WithWriter)`, where the
	entity says once what relates it to the other. C# writes `n => Novel.WithWriter(n)` and hands
	the row in; here the relationship is a function answering with the condition, and the row it
	reads is found among the query's by type.
**/
class GenericJoinTests extends TestCase {
	/**
		The join brings in `table` and matches the outer key against the target's own. Which side each
		lands on is how the relationship was written, and the same join either way, so the pair is what
		is asserted.
	**/
	static function assertJoinedOn(select:SelectExpression, type:JoinType, table:String, outerColumn:String, targetColumn:String):Void {
		final join = select.joinOfType(type);
		Assert.equals(table, join.Source.tableName());

		final on = join.On.binary(Equal);
		final target = select.sourceOf(on.Left) == join.Source ? on.Left : on.Right;
		final outer = target == on.Left ? on.Right : on.Left;

		outer.column(outerColumn);
		Assert.equals(select.Source.Alias, select.sourceAlias(outer));
		target.column(targetColumn);
		Assert.equals(join.Source.Alias, select.sourceAlias(target));
	}

	function testFromGeneric_InnerJoinOn_UsesTheRelationship() {
		final select = Query.select(GenericNovel)
			.InnerJoin(GenericNovel.WithWriter)
			.ToExpression();

		Assert.equals("novels", select.selectTableName());
		assertJoinedOn(select, Inner, "writers", "writerId", "id");
	}

	function testTheRelationship_MatchesTheExplicitKeyForm() {
		Assert.skip("InnerJoin(table, outerKey, innerKey): key-based join overload not in this port");
	}

	function testLeftJoin_UsesTheRelationship() {
		final select = Query.select(GenericNovel).LeftJoin(GenericNovel.WithWriter).ToExpression();

		assertJoinedOn(select, Left, "writers", "writerId", "id");
	}

	function testDeclaredSchema_FromGeneric_JoinsTheRelationship() {
		// An entity without a table name is a table named after it, as in C#.
		final select = Query.select(GenericArticle).InnerJoin(GenericArticle.WithEditor).ToExpression();

		assertJoinedOn(select, Inner, "GenericEditor", "editorId", "id");
	}
}
