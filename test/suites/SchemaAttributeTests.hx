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
	`SchemaAttributeTests.cs` — declaring on the entity what would otherwise take a builder lambda.
**/
class SchemaAttributeTests extends TestCase {
	static function Config():DatabaseConfiguration {
		return new DatabaseConfiguration(new SqlTranslator());
	}

	static function Column(table:DatabaseTableDefinition, name:String):DatabaseColumnDefinition {
		return table.Columns.single(c -> c.Name == name);
	}

	// ---- unbounded text ----

	function testColumnText_IsUnboundedRatherThanLong() {
		final articles = DatabaseInitializer.Build(SaBlog, Config()).Snapshot().Tables.single(t -> t.TableName == "articles");

		Assert.equals(DatabaseColumnType.Text, Column(articles, "body").Type);
		Assert.isNull(Column(articles, "body").MaxLength);

		Assert.equals(DatabaseColumnType.NText, Column(articles, "translated").Type);

		// A string with nothing said about it is unbounded too.
		Assert.equals(DatabaseColumnType.VarChar, Column(articles, "headline").Type);
		Assert.isNull(Column(articles, "headline").MaxLength);
	}

	/** Text is unbounded and a maximum length bounds it. Saying both is a contradiction. */
	function testColumnText_AndAMaxLength_IsRefused() {
		final error = Assert.throwsMessage(() -> DatabaseInitializer.Build(SaContradictorySchema, Config()));
		Assert.contains("[ColumnText] and [ColumnMaxLength]", error);
	}

	// ---- an attribute core knows nothing about ----

	function testAnAttributeCoreDoesNotKnow_StillContributes() {
		Assert.skip("IDbSchemaAttribute: user-defined attribute classes not ported (Haxe metadata is data, not code)");
	}

	function testEveryAttributeOnAGetterOnlyPropertyGetsTheColumn() {
		Assert.skip("DbGenerated<T>: generated-column property type not ported");
	}

	function testEveryStageWorksForAnAttributeCoreNeverHeardOf() {
		Assert.skip("IDbSchemaAttribute: user-defined attribute classes not ported (Haxe metadata is data, not code)");
	}

	function testTheTrigramAttribute_DeclaresWhatTheBuilderDoes() {
		Assert.skip("PgTrgm: PostgreSQL extension");
	}
}

@tableName("articles")
private class SaArticle {
	public var id:Int = 0;

	@columnText
	public var body:Null<String>;

	@columnText({unicode: true})
	public var translated:Null<String>;

	public var headline:Null<String>;

	public function new() {}
}

private class SaBlog implements IDbSchema {
	public final Articles:DbTable<SaArticle> = DbTable.of();

	public function new() {}
}

@tableName("contradiction")
private class SaContradiction {
	public var id:Int = 0;

	@columnText
	@columnMaxLength(40)
	public var both:Null<String>;

	public function new() {}
}

private class SaContradictorySchema implements IDbSchema {
	public final Rows:DbTable<SaContradiction> = DbTable.of();

	public function new() {}
}
