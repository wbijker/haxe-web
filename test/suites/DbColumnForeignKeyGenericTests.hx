package suites;

import codequery.migrations.*;
import codequery.migrations.DatabaseTableConstraint;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("client_contact")
class ClientContact {
	public var id:Int = 0;
	public var code:String = "";

	public function new() {}
}

/** Keyed by something other than id, and by a column that is renamed on the way out. */
@tableName("supplier")
class Supplier {
	@:primaryKey @columnName("supplier_ref") public var reference:String = "";

	public function new() {}
}

@tableName("job")
class Job {
	public var id:Int = 0;
	@:foreignKey(ClientContact) public var clientContactId:Int = 0;
	@:foreignKey(ClientContact, column = "code") public var clientContactCode:String = "";
	@:foreignKey(Supplier, onDelete = Cascade) public var supplierRef:String = "";
	@:foreignKey(ClientContact, index = false) public var secondaryContactId:Int = 0;
	// The non-generic spelling, on the same entity: one spelling here, the same either way.
	@:foreignKey(ClientContact) public var billingContactId:Int = 0;

	public function new() {}
}

/** `DbColumnForeignKeyGenericTests.cs`. */
class DbColumnForeignKeyGenericTests extends TestCase {
	static function Fk(column:String):DatabaseForeignKeyConstraint {
		final found = [
			for (c in SchemaInspector.FromType(Job).Constraints)
				if (Std.isOfType(c, DatabaseForeignKeyConstraint) && (cast c : DatabaseForeignKeyConstraint).Columns[0] == column)
					(cast c : DatabaseForeignKeyConstraint)
		];
		return Assert.single(found);
	}

	static function Indexes():Array<DatabaseIndexDefinition> {
		return SchemaInspector.FromType(Job).Indexes;
	}

	function testTypeArgument_ResolvesTheReferencedTable() {
		Assert.equals("client_contact", Fk("clientContactId").ReferencedTable);
	}

	function testNoColumnNamed_TakesTheReferencedEntitysKey() {
		Assert.equals("id", Assert.single(Fk("clientContactId").ReferencedColumns));
	}

	function testNoColumnNamed_TakesAKeyThatIsNotCalledId() {
		final fk = Fk("supplierRef");
		Assert.equals("supplier", fk.ReferencedTable);
		Assert.equals("supplier_ref", Assert.single(fk.ReferencedColumns));
	}

	function testNamedColumn_IsUsedInsteadOfTheKey() {
		Assert.equals("code", Assert.single(Fk("clientContactCode").ReferencedColumns));
	}

	function testReferentialAction_IsCarried() {
		Assert.equals(DatabaseForeignKeyAction.Cascade, Fk("supplierRef").OnDelete);
	}

	function testForeignKeyColumn_IsIndexedByDefault() {
		Assert.isTrue(Lambda.exists(Indexes(), i -> i.Columns.length == 1 && i.Columns[0].ColumnName == "clientContactId"));
	}

	function testIndexFalse_IsNotIndexed() {
		Assert.isFalse(Lambda.exists(Indexes(), i -> Lambda.exists(i.Columns, c -> c.ColumnName == "secondaryContactId")));
	}

	function testStandsAlongsideTheNonGenericSpelling() {
		final fk = Fk("billingContactId");
		Assert.equals("client_contact", fk.ReferencedTable);
		Assert.equals("id", Assert.single(fk.ReferencedColumns));
	}
}
