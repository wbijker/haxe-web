package suites;

import codequery.DbSchema;
import codequery.DbTable;
import codequery.execution.DatabaseConfiguration;
import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.TableCreateExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/**
	`TableMemberConfigurationTests.cs` — the configuration a table member declares reaching the
	schema it is declared on, for a `DbSchema` subclass.
**/
class TableMemberConfigurationTests extends TestCase {
	static function Built():TmcGaugeDb {
		final config = new DatabaseConfiguration(new SqlTranslator()).WithMigrations("bin/codequery-membercfg");
		final db = new TmcGaugeDb(config);
		db.EnsureBuilt();
		return db;
	}

	function testWhatTheMemberSaysReachesTheSchema() {
		final table = Built().Schema.GetTable(TmcGauge);

		Assert.equals("0", table.Columns.single(c -> c.Name == "reading").DefaultValue);
		Assert.isTrue(table.Constraints.ofType(DatabaseCheckConstraint).any(c -> c.Name == "CK_gauges_reading"));
	}

	/** And is what the migration writes, so the column really carries it. */
	function testAndIsWhatTheMigrationWrites() {
		final table = Built().Schema.GetTable(TmcGauge);
		final create = new TableCreateExpression(table.TableName, table.Columns.map(c -> c.ToColumnDefinition()));

		Assert.contains("DEFAULT 0", new SqlTranslator().ToSql(create));
	}

	/** A default is SQL, as the API says — not the word written into every row. */
	function testADefaultIsSqlRatherThanAString() {
		final column = new DatabaseColumnDefinition("created_at", DatabaseColumnType.DateTime, true, {defaultValue: "CURRENT_TIMESTAMP"});

		final create = new TableCreateExpression("events", [column.ToColumnDefinition()]);

		Assert.contains("DEFAULT CURRENT_TIMESTAMP", new SqlTranslator().ToSql(create));
	}
}

@tableName("gauges")
private class TmcGauge {
	public var id:Int = 0;
	public var reading:Int = 0;
	public var label:String = "";

	public function new() {}
}

private class TmcGaugeDb extends DbSchema {
	public final Gauges:DbTable<TmcGauge> = DbTable.of(t -> {
		t.Column(g -> g.reading).Default(() -> 0);
		t.Check("CK_gauges_reading", g -> g.reading >= 0);
	});

	public function new(configuration:DatabaseConfiguration) {
		super(configuration);
	}
}
