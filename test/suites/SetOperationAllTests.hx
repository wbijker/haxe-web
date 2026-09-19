package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class SetOperationRow {
	public var id:Int = 0;

	public function new() {}
}

/** `SetOperationAllTests.cs` — `INTERSECT ALL` / `EXCEPT ALL`. */
class SetOperationAllTests extends TestCase {
	function testIntersectAll_KeepsDuplicates() {
		final select = Query.select(SetOperationRow).IntersectAll(Query.select(SetOperationRow)).ToExpression();

		Assert.equals(SetOperationType.IntersectAll, select.union().Type);
	}

	function testExceptAll_KeepsDuplicates() {
		final select = Query.select(SetOperationRow).ExceptAll(Query.select(SetOperationRow)).ToExpression();

		Assert.equals(SetOperationType.ExceptAll, select.union().Type);
	}
}
