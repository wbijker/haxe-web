package suites;

import codequery.DbTable;
import codequery.IDbSchema;
import codequery.IdentityKind;
import codequery.execution.DatabaseConfiguration;
import codequery.inspection.SchemaInspector;
import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.DbSchemaExtensions;
using codequery.testing.Linq;

/**
	`IdentityKindTests.cs` — the three forms a generated key takes, and what each does with a row
	that carries a key of its own. The spellings are PostgreSQL's, and are skipped as such; what the
	schema records, and what the fluent surface says, is ported.
**/
class IdentityKindTests extends TestCase {
	// --- Declaring the form ---

	function testByDefault_IsWhatAnUndecoratedKeyGets() {
		// The PostgreSQL rendering of the form is that dialect's own; what an undecorated key is declared as is not.
		Assert.equals(IdentityKind.ByDefault, SchemaInspector.FromType(IkByDefaultKey).Columns[0].Identity);
	}

	function testAlways_RendersTheFormThatKeepsTheColumnToItself() {
		Assert.skip("PostgresSqlDriver: GENERATED ALWAYS AS IDENTITY is PostgreSQL's spelling");
	}

	function testSerial_IsWrittenAsATypeRatherThanAKeyword_SmallSerial() {
		Assert.skip("PostgresSqlDriver: SERIAL is PostgreSQL's spelling");
	}

	function testSerial_IsWrittenAsATypeRatherThanAKeyword_Serial() {
		Assert.skip("PostgresSqlDriver: SERIAL is PostgreSQL's spelling");
	}

	function testSerial_IsWrittenAsATypeRatherThanAKeyword_BigSerial() {
		Assert.skip("PostgresSqlDriver: SERIAL is PostgreSQL's spelling");
	}

	function testSerial_OnANonIntegerColumn_IsRefusedByName() {
		Assert.skip("PostgresSqlDriver: SERIAL is PostgreSQL's spelling");
	}

	function testADialectWithOneIdentityForm_RendersItWhicheverIsAsked() {
		Assert.skip("MySqlSqlDriver/MssqlSqlDriver: no MySQL or SQL Server dialect in this port");
	}

	function testFluentIdentity_SaysTheSameThingAsTheAttribute() {
		final definition = SchemaInspector.FromType(IkByDefaultKey);
		final builder = new EntityTableBuilder<IkByDefaultKey>(definition);
		builder.Column(x -> x.id).Identity(IdentityKind.Always);

		// The PostgreSQL DDL is that dialect's; the column carries the same form the attribute declares.
		Assert.equals(SchemaInspector.FromType(IkAlwaysKey).Columns[0].Identity,
			definition.Columns.single(c -> c.Name == "id").Identity);
		Assert.equals(IdentityKind.Always, definition.Columns.single(c -> c.Name == "id").Identity);
	}

	/** The form as a table declares it — the configure lambda on the member. */
	function testFluentOnTheTableMember_IsWhatTheBuiltSchemaCarries() {
		final db = DatabaseInitializer.Build(IkFluentAlwaysDb, new DatabaseConfiguration(new SqlTranslator()));
		final table = db.Snapshot().GetTable(IkByDefaultRow);

		Assert.equals(IdentityKind.Always, table.Columns.single(c -> c.Name == "id").Identity);
		// The PostgreSQL rendering of it is that dialect's own.
	}

	function testFluentPrimaryKey_CarriesTheFormWithTheKey() {
		final definition = SchemaInspector.FromType(IkByDefaultKey);
		final builder = new EntityTableBuilder<IkByDefaultKey>(definition);
		builder.Column(x -> x.id).PrimaryKey(null, true, null, IdentityKind.Always);

		Assert.equals(IdentityKind.Always, definition.Columns.single(c -> c.Name == "id").Identity);
	}

	// --- Changing the form ---

	function testChangingTheForm_IsOneActionOfItsOwn() {
		Assert.skip("PostgresSqlDriver: ALTER COLUMN … SET GENERATED is PostgreSQL's spelling");
	}

	function testGainingAndLosingAnIdentity_AddsAndDropsIt() {
		Assert.skip("PostgresSqlDriver: ALTER COLUMN … ADD/DROP IDENTITY is PostgreSQL's spelling");
	}

	function testMovingBetweenSerialAndIdentity_IsRefusedRatherThanApproximated() {
		Assert.skip("PostgresSqlDriver: SERIAL is PostgreSQL's spelling");
	}

	function testAColumnThatKeepsItsForm_AltersAsItAlwaysHas() {
		Assert.skip("PostgresSqlDriver: dialect-specific ALTER COLUMN");
	}

	// --- The snapshot ---

	function testTheFormSurvivesTheSnapshot_AndAChangeToItIsAChange() {
		final declared = SchemaInspector.FromType(IkAlwaysKey);
		final yaml = SchemaSnapshot.ToYaml(DatabaseSchema.FromTables([declared]));

		final read = SchemaSnapshot.FromYaml(yaml).Tables.single();

		Assert.equals(IdentityKind.Always, read.Columns.single(c -> c.Name == "id").Identity);
		Assert.isFalse(SchemaInspector.FromType(IkByDefaultKey).Columns.single(c -> c.Name == "id")
			.Equals(read.Columns.single(c -> c.Name == "id")));
	}

	function testTheOrdinaryFormIsNotWrittenDown() {
		final yaml = SchemaSnapshot.ToYaml(DatabaseSchema.FromTables([SchemaInspector.FromType(IkByDefaultKey)]));

		Assert.doesNotContain("identity", yaml.toLowerCase());
	}

	// --- Inserting a key of one's own ---

	function testAKeyOfOnesOwn_IntoAnAlwaysColumn_SaysOverridingSystemValue() {
		Assert.skip("Profiler/Logger/Interceptor: not ported");
	}

	function testAKeyLeftToTheDatabase_SaysNothing_BecauseTheColumnIsNotSent() {
		Assert.skip("Profiler/Logger/Interceptor: not ported");
	}

	function testAKeyOfOnesOwn_IntoAByDefaultColumn_NeedsNothingSaid() {
		Assert.skip("Profiler/Logger/Interceptor: not ported");
	}

	// --- Setting the sequence ---

	function testPostgres_AsksTheTableForTheSequenceBehindTheColumn() {
		Assert.skip("PostgresSqlDriver.BuildResyncIdentitySql: dialect-specific");
	}

	function testPostgres_CanWorkTheValueOutFromTheTable() {
		Assert.skip("PostgresSqlDriver.BuildResyncIdentityToMaxSql: dialect-specific");
	}

	function testEachDialectMovesItsOwnCounter() {
		Assert.skip("MssqlSqlDriver/MySqlSqlDriver/SqliteSqlDriver.BuildResyncIdentitySql: dialect-specific");
	}
}

@tableName("t")
private class IkByDefaultKey {
	public var id:Int = 0;

	public function new() {}
}

@tableName("t")
private class IkAlwaysKey {
	@columnPrimaryKey({identity: "Always"})
	public var id:Int = 0;

	public function new() {}
}

@tableName("rows")
private class IkByDefaultRow {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

private class IkFluentAlwaysDb implements IDbSchema {
	public final Rows:DbTable<IkByDefaultRow> = DbTable.of(t -> t.Column(r -> r.id).Identity(IdentityKind.Always));

	public function new() {}
}
