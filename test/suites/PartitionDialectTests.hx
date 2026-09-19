package suites;

import codequery.SqlDate;
import codequery.migrations.DbTablePartition;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.SqlType;
import codequery.sqlexpressions.TablePartition;
import codequery.testing.Assert;
import codequery.testing.TestCase;

class Sale {
	public var id:Int = 0;
	public var customerId:Int = 0;
	public var region:String = "";
	public var saleDate:SqlDate;

	public function new() {}
}

/** Range by date — bounds are real dates, tied to the key type by the compiler. */
class SalesByYear extends DbTablePartition<Sale> {
	override public function Configure(config:IPartitionConfig<Sale>) {
		config.PartitionBy(s -> s.saleDate)
			.AsRange()
			.Add("sales_2024", new Date(2024, 0, 1, 0, 0, 0), new Date(2025, 0, 1, 0, 0, 0))
			.Add("sales_2025", new Date(2025, 0, 1, 0, 0, 0), new Date(2026, 0, 1, 0, 0, 0));
	}
}

/** List by string values. */
class SalesByRegion extends DbTablePartition<Sale> {
	override public function Configure(config:IPartitionConfig<Sale>) {
		config.PartitionBy(s -> s.region).AsList().Add("emea", ["DE", "FR"]).Add("apac", ["JP", "AU"]);
	}
}

/** Hash by int, sized to a number of tables. */
class SalesByCustomer extends DbTablePartition<Sale> {
	override public function Configure(config:IPartitionConfig<Sale>) {
		config.PartitionBy(s -> s.customerId).AsHash().Partitions(4);
	}
}

/** Expression key: partition by the year part of a date. */
class SalesByYearExpr extends DbTablePartition<Sale> {
	override public function Configure(config:IPartitionConfig<Sale>) {
		config.PartitionBy(s -> Sql.Year(s.saleDate)).AsRange().Add("sales_2024", 2024, 2025);
	}
}

class EmptyPartition extends DbTablePartition<Sale> {
	override public function Configure(config:IPartitionConfig<Sale>) {}
}

/**
	`PartitionDialectTests.cs`: strongly-typed table partitioning, rendered as PostgreSQL's
	declarative partitioning — the one dialect this port renders.
**/
class PartitionDialectTests extends TestCase {
	static function Table(partition:TablePartition, columns:Array<ColumnDefinition>):CreateTableExpression {
		return new CreateTableExpression("sales", columns, null, null, false, partition);
	}

	static function Col(name:String, type:SqlType):ColumnDefinition {
		return new ColumnDefinition(name, type);
	}

	static function RangeByYear():CreateTableExpression {
		return Table(new SalesByYear().Build(), [Col("id", SqlInt), Col("saleDate", SqlTimestamp)]);
	}

	static function ListByRegion():CreateTableExpression {
		return Table(new SalesByRegion().Build(), [Col("id", SqlInt), Col("region", SqlText)]);
	}

	static function HashByCustomer():CreateTableExpression {
		return Table(new SalesByCustomer().Build(), [Col("id", SqlInt), Col("customerId", SqlInt)]);
	}

	// --- The typed builder renders values, not strings ---

	function testRangeBounds_AreRenderedFromTypedDateTimes() {
		final partition = new SalesByYear().Build();
		Assert.equals("saleDate", partition.KeyExpression);
		Assert.equals(PartitionStrategy.Range, partition.Strategy);
		Assert.equals("'2024-01-01 00:00:00'", partition.Partitions[0].From);
		Assert.equals("'2025-01-01 00:00:00'", partition.Partitions[0].To);
	}

	function testExpressionKey_RendersDatePartExtraction() {
		Assert.equals("EXTRACT(YEAR FROM saleDate)", new SalesByYearExpr().Build().KeyExpression);
	}

	// --- PostgreSQL: declarative partitioning with child tables ---

	function testPostgres_Range_EmitsPartitionByAndChildTables() {
		final sql = new SqlTranslator().ToSql(RangeByYear());
		Assert.contains("PARTITION BY RANGE (saleDate)", sql);
		Assert.contains("CREATE TABLE sales_2024 PARTITION OF sales FOR VALUES FROM ('2024-01-01 00:00:00') TO ('2025-01-01 00:00:00')", sql);
		Assert.contains("CREATE TABLE sales_2025 PARTITION OF sales FOR VALUES FROM ('2025-01-01 00:00:00') TO ('2026-01-01 00:00:00')", sql);
	}

	function testPostgres_List_EmitsForValuesIn() {
		final sql = new SqlTranslator().ToSql(ListByRegion());
		Assert.contains("PARTITION BY LIST (region)", sql);
		Assert.contains("FOR VALUES IN ('DE', 'FR')", sql);
		Assert.contains("FOR VALUES IN ('JP', 'AU')", sql);
	}

	function testPostgres_Hash_ExpandsCountIntoModulusRemainderChildren() {
		final sql = new SqlTranslator().ToSql(HashByCustomer());
		Assert.contains("PARTITION BY HASH (customerId)", sql);
		Assert.contains("sales_p0 PARTITION OF sales FOR VALUES WITH (MODULUS 4, REMAINDER 0)", sql);
		Assert.contains("sales_p3 PARTITION OF sales FOR VALUES WITH (MODULUS 4, REMAINDER 3)", sql);
	}

	// --- Other dialects ---

	function testMySql_Range_EmitsValuesLessThan() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testMySql_Hash_SizesWithPartitionsCount() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlServer_Range_EmitsFunctionSchemeAndOnClause() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_ListAndHash_ThrowLoudly() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_ExpressionKey_ThrowsLoudly() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlite_Partitioning_ThrowsLoudly() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	// --- Non-partitioned tables are unaffected ---

	function testNoPartition_RendersOrdinaryCreateTable_OnEveryDialect() {
		final sql = new SqlTranslator().ToSql(new CreateTableExpression("t", [Col("id", SqlInt)]));
		Assert.contains("CREATE TABLE", sql);
		Assert.doesNotContain("PARTITION", sql);
	}

	// --- Configure must define a key ---

	function testConfigure_WithoutPartitionBy_Throws() {
		Assert.throws(() -> new EmptyPartition().Build());
	}
}
