package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`RoutineDiscoveryTests.cs`.

	A `DbSchema` discovering its views, procedures and functions as routines in its snapshot. The
	port's `DbView` holds a definition but no snapshot lists it as a routine, and there are no
	procedures or functions at all.
**/
class RoutineDiscoveryTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testDiscovers_View_Procedure_And_Function() {
		Assert.skip(Reason);
	}

	function testView_Uses_DbViewName_Attribute() {
		Assert.skip("DbSchema.Routines: views are not routines in the snapshot of this port");
	}

	function testMaterialized_View_Kind_RendersMaterialized() {
		Assert.skip("DbViewKind.Materialized: materialized views not ported");
	}

	function testProcedure_And_Function_Render_Their_Ddl() {
		Assert.skip(Reason);
	}

	function testFluentRegistration_IsNotDuplicated_ByDiscovery() {
		Assert.skip("DbSchema.Routines: views are not routines in the snapshot of this port");
	}
}
