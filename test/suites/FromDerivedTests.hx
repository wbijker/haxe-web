package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `FromDerivedTests.cs` — `DbTable<T>.FromDerived<TDerived>()`, refining a JSON member's type. */
class FromDerivedTests extends TestCase {
	function testFromDerived_KeepsSameSource() {
		Assert.skip("DbTable.FromDerived: querying a table as a subtype of its entity is not in this port");
	}

	function testFromDerived_BindsToDerivedType_ForStronglyTypedFieldAccess() {
		Assert.skip("JsonExpression: JSON not ported");
	}
}
