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
		Assert.skip("DbTable(this) member binding (DbTable.Configuration): not ported");
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
		Assert.skip("DbTable(this) member binding (DbTable.From needing a built schema): not ported");
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
