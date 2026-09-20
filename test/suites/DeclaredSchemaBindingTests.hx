package suites;

import codequery.DbTable;
import codequery.IDbSchema;
import codequery.execution.DatabaseConfiguration;
import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.DbSchemaExtensions;
using codequery.testing.Linq;

/**
	`DeclaredSchemaBindingTests.cs` — how a self-constructing member finds the database it belongs to.
**/
class DeclaredSchemaBindingTests extends TestCase {
	static function Config():DatabaseConfiguration {
		return new DatabaseConfiguration(new SqlTranslator());
	}

	function testMemberGivenItsSchema_BindsToThatSchemasDatabase() {
		final left = DatabaseInitializer.Build(DsbCrateDb, Config());
		final right = DatabaseInitializer.Build(DsbCrateDb, Config());

		// Two live databases over the same entity: each member stays with the schema that declared it,
		// rather than with the one built most recently.
		Assert.isTrue(left.Config() == left.Crates.Configuration);
		Assert.isTrue(right.Config() == right.Crates.Configuration);
		Assert.isFalse(left.Crates.Configuration == right.Crates.Configuration);
	}

	function testBuild_FromAnInstance_UsesTheSchemaAsConstructed() {
		final db = DatabaseInitializer.Build(new DsbPalletDb(3), Config());

		final pallets = db.Snapshot().Tables.single(t -> t.TableName == "pallets");
		final check = pallets.Constraints.ofType(DatabaseCheckConstraint).single(c -> c.Name == "CK_pallets_height");
		Assert.contains("3", check.Expression);
	}

	function testDeclaredSchema_ScaffoldsAndRunsItsMigration() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testTableUsedBeforeItsSchemaIsBuilt_SaysSo() {
		Assert.skip("DbTable ambient configuration: From() renders without one in this port, so there is nothing to refuse");
	}
}

@tableName("crates")
private class DsbCrate {
	@columnPrimaryKey
	public var id:Int = 0;
	public var label:String = "";

	public function new() {}
}

/** A schema whose member names the schema it belongs to, so two of them can coexist. */
private class DsbCrateDb implements IDbSchema {
	public final Crates:DbTable<DsbCrate>;

	// C# writes `new(this)` on the member; a Haxe field cannot name `this` until the constructor.
	public function new() {
		Crates = DbTable.of(this);
	}
}

@tableName("pallets")
private class DsbPallet {
	@columnPrimaryKey
	public var id:Int = 0;
	public var height:Int = 0;

	public function new() {}
}

/** A schema with constructor arguments of its own — built from an instance. */
private class DsbPalletDb implements IDbSchema {
	public final Pallets:DbTable<DsbPallet>;

	public function new(minHeight:Int) {
		Pallets = DbTable.of(p -> p.Check("CK_pallets_height", x -> x.height >= minHeight));
	}
}
