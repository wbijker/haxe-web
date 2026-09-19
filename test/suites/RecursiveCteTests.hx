package suites;

import codequery.Query;
import codequery.queries.ISelectQuery;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class RecursiveEmployee {
	public var id:Int = 0;
	public var managerId:Null<Int>;
	public var name:String = "";

	public function new() {}
}

/** `RecursiveCteTests.cs` — `WITH RECURSIVE name AS (anchor UNION ALL recursive-member) SELECT …`. */
class RecursiveCteTests extends TestCase {
	// A hierarchy walk: top-level employees, then everyone reporting (transitively) under them.
	static function orgChart():ISelectQuery<RecursiveEmployee> {
		return Query.select(RecursiveEmployee)
			.Where(e -> e.managerId == null)
			.Recursive("org", org -> Query.select(RecursiveEmployee)
				.InnerJoin(org, (e, parent) -> e.managerId == parent.id)
				.Select((e, parent) -> {id: e.id, managerId: e.managerId, name: e.name}));
	}

	function testRecursive_IsANamedRecursiveCte() {
		// The query reads from the CTE, so the recursion is on the statement it selects from.
		final body = orgChart().ToExpression().subquery();

		Assert.isTrue(body.IsCte);
		Assert.isTrue(body.IsRecursive);
		Assert.equals("org", body.CteName);
	}

	function testRecursive_AnchorAndRecursiveMembers_Present() {
		final select = orgChart().ToExpression().subquery();

		// Anchor: the base employees filtered to top-level.
		final anchor = select.whereBinary(Equal);
		anchor.Left.column("managerId");
		anchor.Right.nullConst();

		// Recursive member: a UNION ALL arm that joins back to the CTE by name.
		final member = select.union();
		Assert.equals(SetOperationType.UnionAll, member.Type);

		// The CTE is referenced by name, as a table — which is what keeps the recursion out of the tree.
		final join = member.Query.joinOfType(Inner);
		Assert.equals("org", join.Source.tableName());
		join.On.columnComparison("managerId", Equal, "id");
	}

	function testRecursive_SqlServer_OmitsRecursiveKeyword() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}
}
