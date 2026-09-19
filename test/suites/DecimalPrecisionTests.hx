package suites;

import codequery.DbTable;
import codequery.migrations.DatabaseColumnDefinition;
import codequery.migrations.SchemaBuilder;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SqlType;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`DecimalPrecisionTests.cs` — how exact a decimal column is, said on the field with
	`@columnPrecision`, C#'s `[DbColumnPrecision]`. A decimal with nothing said about it keeps the
	dialect's own idea of one.
**/
class DecimalPrecisionTests extends TestCase {
	static function column(name:String):DatabaseColumnDefinition {
		final found = SchemaBuilder.Of(new RateDb()).Table("rates").Column(name);
		Assert.notNull(found, 'column $name');
		return found;
	}

	// --- What the field says -----------------------------------------------------------------------

	function testTheAttributeSaysPrecisionAndScale() {
		Assert.equals(SqlType.SqlDecimal(12, 4), column("factor").SqlType());
		Assert.equals(SqlType.SqlDecimal(9, 3), column("adjustment").SqlType());
	}

	function testScaleDefaultsToNone() {
		Assert.equals(SqlType.SqlDecimal(18, 0), column("cents").SqlType());
	}

	function testSayingNothingLeavesItToTheDialect() {
		Assert.isFalse(column("plain").SqlType().match(SqlDecimal(_, _)), "no precision is declared");
	}

	// --- What the fluent surface says --------------------------------------------------------------

	function testTheFluentSurfaceSaysTheSameThing() {
		Assert.skip("EntityTableBuilder: fluent column configuration not ported");
	}

	function testItLeavesTheTypeAlone() {
		Assert.skip("EntityTableBuilder: fluent column configuration not ported");
	}

	// --- What reaches the database -----------------------------------------------------------------

	function testEachDialectDeclaresIt() {
		final table = SchemaBuilder.Of(new RateDb()).Table("rates");
		final create = new SqlTranslator().ToDdl(CreateTable(table));

		Assert.contains("factor DECIMAL(12, 4)", create);

		// Nothing said, nothing declared — the dialect decides.
		Assert.doesNotContain("plain DECIMAL(", create);
	}

	// --- What is refused ---------------------------------------------------------------------------

	function testAPrecisionNoDatabaseWouldTakeIsRefused() {
		final scaleTooBig = Assert.throwsMessage(() -> SchemaBuilder.Of(new TooMuchScaleDb()));
		Assert.contains("cannot keep more after the point", scaleTooBig);
		Assert.contains("amount", scaleTooBig);

		Assert.throws(() -> SchemaBuilder.Of(new NoDigitsDb()));
	}

	function testAndSoIsTheFluentSurface() {
		Assert.skip("EntityTableBuilder: fluent column configuration not ported");
	}

	// --- And through a database --------------------------------------------------------------------

	function testItSurvivesAMigrationAndARoundTrip() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}

@tableName("rates")
class Rate {
	public var id:Int = 0;

	/** Four digits after the point, twelve in all. */
	@columnPrecision(12, 4) public var factor:Float = 0;

	/** Whole units, said as a precision with no scale. */
	@columnPrecision(18) public var cents:Float = 0;

	/** Nothing said: the dialect's own decimal. */
	public var plain:Float = 0;

	/** Absent or exact, both. */
	@columnPrecision(9, 3) public var adjustment:Null<Float>;

	public function new() {}
}

class RateDb {
	public final Rates:DbTable<Rate> = DbTable.of();

	public function new() {}
}

class TooMuchScale {
	public var id:Int = 0;
	@columnPrecision(4, 6) public var amount:Float = 0;

	public function new() {}
}

class TooMuchScaleDb {
	public final Amounts:DbTable<TooMuchScale> = DbTable.of();

	public function new() {}
}

class NoDigits {
	public var id:Int = 0;
	@columnPrecision(0) public var amount:Float = 0;

	public function new() {}
}

class NoDigitsDb {
	public final Amounts:DbTable<NoDigits> = DbTable.of();

	public function new() {}
}
