package suites;

import codequery.DbTable;
import codequery.Decimal;
import codequery.IDbSchema;
import codequery.Sql;
import codequery.TimeSpan;
import codequery.execution.DatabaseConfiguration;
import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.DbSchemaExtensions;
using codequery.testing.Linq;
using codequery.testing.TestSchemaHelpers;

/**
	`FluentColumnBuilderTests.cs` — the fluent table surface: a table class that configures itself,
	a column builder per type, and a foreign key that has to point at a column of the same type.
**/
class FluentColumnBuilderTests extends TestCase {
	static function Config():DatabaseConfiguration {
		return new DatabaseConfiguration(new SqlTranslator());
	}

	static function Column(table:DatabaseTableDefinition, name:String):DatabaseColumnDefinition {
		return table.Columns.single(c -> c.Name == name);
	}

	/** A snapshot with the parts table defined into it, ready to configure. */
	static function Defined():SchemaSnapshot {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(FcPart, "parts");
		return snapshot;
	}

	// ---- a table that configures itself ----

	function testATableClass_ConfiguresItself() {
		final parts = DatabaseInitializer.Build(FcCatalogue, Config()).Snapshot().Tables.single(t -> t.TableName == "parts");

		Assert.equals(40, Column(parts, "code").MaxLength);
		Assert.isFalse(Column(parts, "code").IsNullable);
		Assert.equals(12, Column(parts, "cost").Precision);
		Assert.equals(4, Column(parts, "cost").Scale);
	}

	function testTheConstructorLambda_StillWorks_AndRunsAfterConfigure() {
		final suppliers = DatabaseInitializer.Build(FcPlainSchema, Config()).Snapshot().Tables.single(t -> t.TableName == "suppliers");
		Assert.equals(80, Column(suppliers, "name").MaxLength);

		// Both run, and the lambda is the later word: it amends what the class settled.
		final amended = new FcAmended();
		final snapshot = Defined();
		amended.ApplyConfiguration(snapshot);

		Assert.equals(999, snapshot.Tables.single().Columns.single(c -> c.Name == "code").MaxLength);
	}

	// ---- a builder per type ----

	function testEachTypeIsConfiguredByItsOwnBuilder() {
		final parts = DatabaseInitializer.Build(FcTyped, Config()).Snapshot().Tables.single(t -> t.TableName == "parts");

		Assert.equals(DatabaseColumnType.NChar, Column(parts, "code").Type);
		Assert.equals(8, Column(parts, "code").MaxLength);
		Assert.equals(DatabaseColumnType.Text, Column(parts, "description").Type);
		Assert.equals(9, Column(parts, "discount").Precision);
		Assert.equals(DatabaseColumnType.Date, Column(parts, "createdAt").Type);
		Assert.equals(DatabaseColumnType.Time, Column(parts, "window").Type);
		Assert.equals(DatabaseColumnType.Binary, Column(parts, "thumbnail").Type);
		Assert.equals(32, Column(parts, "thumbnail").MaxLength);
	}

	/** The builder a column hands back is its own type, and stays so through the common members. */
	function testChainingKeepsTheTypesOwnBuilder() {
		final snapshot = Defined();
		final t = snapshot.Entity(FcPart);

		final text:StringColumnBuilder<FcPart> = t.Column(p -> p.code);
		final money:DecimalColumnBuilder<FcPart, Decimal> = t.Column(p -> p.cost);
		final bytes:BinaryColumnBuilder<FcPart> = t.Column(p -> p.thumbnail);
		final plain:ColumnBuilder<FcPart, Int> = t.Column(p -> p.id);

		// NotNull() hands back the string builder, so MaxLength is still there afterwards.
		text.NotNull().MaxLength(64).Comment("code").MaxLength(65);
		money.Null().Precision(10, 2);

		Assert.equals(65, snapshot.Tables.single().Columns.single(c -> c.Name == "code").MaxLength);
		Assert.equals(10, snapshot.Tables.single().Columns.single(c -> c.Name == "cost").Precision);
		Assert.notNull(bytes);
		Assert.notNull(plain);
	}

	/** Unicode converts whatever the column is, in whichever order it is said. */
	function testUnicodeConvertsTheTextTypeEitherWayRound() {
		final snapshot = Defined();
		final t = snapshot.Entity(FcPart);

		t.Column(p -> p.code).MaxLength(20).Unicode();
		Assert.equals(DatabaseColumnType.NVarChar, snapshot.Tables.single().Columns.single(c -> c.Name == "code").Type);

		t.Column(p -> p.code).Unicode(false);
		Assert.equals(DatabaseColumnType.VarChar, snapshot.Tables.single().Columns.single(c -> c.Name == "code").Type);

		t.Column(p -> p.description).Unicode().Text();
		Assert.equals(DatabaseColumnType.NText, snapshot.Tables.single().Columns.single(c -> c.Name == "description").Type);
	}

	// ---- the column a property maps to ----

	/** The builder configures the column the property maps to, not a column named after the property. */
	function testConfiguringByPropertyFindsTheMappedColumn() {
		final table = DatabaseInitializer.Build(FcMappedSchema, Config()).Snapshot().Tables.single(t -> t.TableName == "mapped");

		Assert.equals(["id", "norm", "part_no"], table.Columns.map(c -> c.Name).sorted());

		Assert.equals(64, Column(table, "part_no").MaxLength);
		Assert.notNull(Column(table, "norm").GeneratedExpression);
	}

	// ---- foreign keys that have to line up ----

	function testAForeignKeyPointsAtAColumnOfItsOwnType() {
		final keys = DatabaseInitializer.Build(FcKeyed, Config()).Snapshot().Tables.single(t -> t.TableName == "parts")
			.Constraints.ofType(DatabaseForeignKeyConstraint);

		Assert.isTrue(keys.any(k -> k.Columns.single() == "supplierId"
			&& k.ReferencedColumns.single() == "id"
			&& k.ReferencedTable == "suppliers"));

		Assert.isTrue(keys.any(k -> k.Name == "FK_parts_secondary"
			&& k.Columns.single() == "secondarySupplierId"
			&& k.ReferencedColumns.single() == "id"));
	}
}

@tableName("suppliers")
private class FcSupplier {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

@tableName("parts")
private class FcPart {
	public var id:Int = 0;
	public var supplierId:Int = 0;
	public var secondarySupplierId:Null<Int>;
	public var code:String = "";
	public var description:Null<String>;
	public var cost:Decimal = 0;
	public var discount:Null<Decimal>;
	public var createdAt:Date;
	public var window:TimeSpan = 0;
	public var thumbnail:haxe.io.Bytes;

	public function new() {}
}

/** A table that says its own configuration, rather than a lambda in the schema member saying it. */
private class FcParts extends DbTable<FcPart> {
	public function new(?configure:EntityTableBuilder<FcPart>->Void) {
		super(DbTable.tableOf(FcPart), DbTable.entityOf(FcPart), configure);
	}

	override public function Configure(configure:EntityTableBuilder<FcPart>):Void {
		configure.Column(p -> p.code).MaxLength(40).NotNull();
		configure.Column(p -> p.cost).Precision(12, 4);
	}
}

private class FcCatalogue implements IDbSchema {
	public final Suppliers:DbTable<FcSupplier> = DbTable.of();
	public final Parts:FcParts = new FcParts();

	public function new() {}
}

/** A table with nothing to say overrides nothing, and is configured as it always was. */
private class FcPlainSchema implements IDbSchema {
	public final Suppliers:DbTable<FcSupplier> = DbTable.of(t -> t.Column(s -> s.name).MaxLength(80));

	public function new() {}
}

private class FcAmended extends FcParts {
	public function new() {
		super(t -> t.Column(p -> p.code).MaxLength(999));
	}
}

private class FcTyped implements IDbSchema {
	public final Suppliers:DbTable<FcSupplier> = DbTable.of();

	public final Parts:DbTable<FcPart> = DbTable.of(t -> {
		t.Column(p -> p.code).Fixed(8).Unicode();
		t.Column(p -> p.description).Text();
		t.Column(p -> p.discount).Precision(9, 3);
		t.Column(p -> p.createdAt).Date();
		t.Column(p -> p.window).Time();
		t.Column(p -> p.thumbnail).Fixed(32);
	});

	public function new() {}
}

@tableName("mapped")
private class FcMapped {
	public var id:Int = 0;

	@columnName("part_no")
	public var partNo:Null<String>;

	@columnName("norm")
	public var norm:Null<String>;

	public function new() {}
}

private class FcMappedSchema implements IDbSchema {
	public final Rows:DbTable<FcMapped> = DbTable.of(t -> {
		t.Column(m -> m.partNo).MaxLength(64);
		t.Column(m -> m.norm).Text().Generated(m -> Sql.upper(m.partNo), true);
	});

	public function new() {}
}

private class FcKeyed implements IDbSchema {
	public final Suppliers:DbTable<FcSupplier> = DbTable.of();

	public final Parts:DbTable<FcPart> = DbTable.of(t -> {
		t.Column(p -> p.supplierId).ForeignKey(FcSupplier, s -> s.id);

		// A nullable column still points at a non-nullable key.
		t.Column(p -> p.secondarySupplierId).ForeignKey(FcSupplier, s -> s.id, null, null, "FK_parts_secondary");
	});

	public function new() {}
}
