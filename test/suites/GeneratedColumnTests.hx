package suites;

import codequery.Decimal;
import codequery.migrations.*;
import codequery.migrations.IMigrationPrompt;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`GeneratedColumnTests.cs` — generated/computed columns emitted as part of the CREATE TABLE DDL
	per driver, and migrated. The CREATE TABLE expectations are each a dialect's own spelling; the
	plans the migration planner makes are rendered here in the one generic dialect.
**/
class GeneratedColumnTests extends TestCase {
	/** The C# `Build`'s table, before its generated column is said. */
	static function Table():DatabaseTableDefinition {
		final def = new DatabaseTableDefinition("Book");
		def.AddColumn("id", DatabaseColumnType.Int, false);
		def.AddColumn("price", DatabaseColumnType.Decimal, false);
		def.AddColumn("pageCount", DatabaseColumnType.Int, false);
		def.AddColumn("pricePerPage", DatabaseColumnType.Decimal);
		return def;
	}

	/** The C# `Build(stored)` with its default expression. */
	static function Divided(stored:Bool):DatabaseTableDefinition {
		final def = Table();
		new EntityTableBuilder<GcBook>(def).Column(b -> b.pricePerPage).Generated(b -> b.price / b.pageCount, stored);
		return def;
	}

	/** The C# `Build(stored, b => b.Price * b.PageCount)`. */
	static function Multiplied(stored:Bool):DatabaseTableDefinition {
		final def = Table();
		new EntityTableBuilder<GcBook>(def).Column(b -> b.pricePerPage).Generated(b -> b.price * b.pageCount, stored);
		return def;
	}

	static function PlanChange(from:DatabaseTableDefinition, to:DatabaseTableDefinition):Array<SchemaChangeExpression> {
		return MigrationPlanner.Plan(SchemaDiff.Create(SchemaSnapshot.FromTables([from]), SchemaSnapshot.FromTables([to])),
			new NonInteractiveMigrationPrompt());
	}

	static function Sql(ops:Array<SchemaChangeExpression>):String {
		return ops.map(op -> new SqlTranslator().ToSql(op)).join(";\n");
	}

	function testPostgres_StoredOnly() {
		Assert.skip("PostgresSqlDriver: dialect-specific generated-column DDL");
	}

	function testPostgres_VirtualThrows() {
		Assert.skip("PostgresSqlDriver: dialect-specific generated-column DDL");
	}

	function testMySql_StoredAndVirtual() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlite_StoredAndVirtual() {
		Assert.skip("SqliteSqlDriver: dialect-specific generated-column DDL");
	}

	function testSqlServer_ComputedAndPersisted() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testTernary_RendersCase() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testChangedGeneratedExpression_IsAlteredInPlace_WithSetExpression() {
		// The generation expression changes (price / pageCount -> price * pageCount). A column that stays
		// generated is altered in place with a single ALTER … SET EXPRESSION, not a lossy drop + add.
		final ops = PlanChange(Divided(true), Multiplied(true));

		Assert.single(ops.filter(o -> Std.isOfType(o, AlterColumnExpression)));

		final sql = Sql(ops);

		Assert.startsWith("ALTER TABLE Book ALTER COLUMN pricePerPage SET EXPRESSION AS (", sql);
		Assert.doesNotContain("DROP COLUMN pricePerPage", sql);
		Assert.doesNotContain("ADD COLUMN pricePerPage", sql);
	}

	function testChangedGeneratedExpression_PrePostgres17_FallsBackToDropAndReadd() {
		Assert.skip("PostgresSqlDriver.TargetMajorVersion: a PostgreSQL version's own spelling");
	}

	function testChangedGeneratedExpression_MySql_AltersWithModifyColumn() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testChangedGeneratedExpression_SqlServer_ReDeclaresComputedColumn() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testPlainColumnBecomingGenerated_IsDroppedAndReAdded() {
		// A plain column turning into a generated one is a redeclaration, not an in-place ALTER.
		final ops = PlanChange(Table(), Divided(true));

		final sql = Sql(ops);

		Assert.contains("DROP COLUMN pricePerPage", sql);
		Assert.contains("ADD COLUMN pricePerPage DECIMAL GENERATED ALWAYS AS (", sql);
		Assert.doesNotContain("ALTER COLUMN pricePerPage", sql);
	}

	function testDbGenerated_IsInspectedAndRendered() {
		Assert.skip("DbGenerated<T>: generated-column property type not ported");
	}
}

private class GcBook {
	public var id:Int = 0;
	public var price:Decimal = 0;
	public var pageCount:Int = 0;
	public var pricePerPage:Decimal = 0;

	public function new() {}
}
