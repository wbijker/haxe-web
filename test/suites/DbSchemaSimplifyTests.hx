package suites;

import codequery.DbSchema;
import codequery.DbTable;
import codequery.execution.DatabaseConfiguration;
import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/** `DbSchemaSimplifyTests.cs`. */
class DbSchemaSimplifyTests extends TestCase {
	function testTable_Builds_Columns_Attributes_And_FluentConfigure() {
		final db = new SimpShopDb(new DatabaseConfiguration(new SqlTranslator()));
		db.EnsureBuilt();

		final review = db.Schema.GetTable(SimpReview);

		// Data properties become columns.
		Assert.equals(["bookId", "comment", "id", "rating", "reviewDate", "reviewerName"], review.Columns.map(c -> c.Name).sorted());

		// @columnNullable(false) / @columnMaxLength
		final reviewer = review.Columns.single(c -> c.Name == "reviewerName");
		Assert.isFalse(reviewer.IsNullable);
		Assert.equals(100, reviewer.MaxLength);
		Assert.equals(1000, review.Columns.single(c -> c.Name == "comment").MaxLength);

		// @columnForeignKey("SimpBook")
		Assert.isTrue(review.Constraints.ofType(DatabaseForeignKeyConstraint).any(fk -> fk.Columns.indexOf("bookId") >= 0));

		// Fluent Configure — a single PK (explicit replaces the id convention) named PK_reviews + the Check.
		final pks = review.Constraints.ofType(DatabasePrimaryKeyConstraint);
		Assert.single(pks);
		Assert.equals(["id"], pks[0].Columns);
		Assert.equals("PK_reviews", pks[0].Name);
		Assert.isTrue(review.Constraints.ofType(DatabaseCheckConstraint).any(ck -> ck.Name == "CK_reviews_rating"));
	}

	function testCheckConstraint_RendersAsBooleanExpression_NotStringLiteral() {
		final db = new SimpShopDb(new DatabaseConfiguration(new SqlTranslator()));
		db.EnsureBuilt();

		final review = db.Schema.GetTable(SimpReview);
		final sql = new SqlTranslator().ToSql(review.ToCreateTableExpression());

		// The check condition is emitted verbatim as SQL, not wrapped in quotes as a string constant.
		Assert.contains("CHECK (rating >= 1 AND rating <= 5)", sql);
		Assert.doesNotContain("CHECK ('", sql);
	}
}

private class SimpBook {
	public var id:Int = 0;
	public var title:String = "";

	public function new() {}
}

private class SimpReview {
	public var id:Int = 0;

	@columnForeignKey("SimpBook")
	public var bookId:Int = 0;

	@columnNullable(false)
	@columnMaxLength(100)
	public var reviewerName:String = "";

	public var rating:Int = 0;

	@columnMaxLength(1000)
	public var comment:Null<String>;

	public var reviewDate:Date;

	public function new() {}
}

private class SimpShopDb extends DbSchema {
	public final Books:DbTable<SimpBook> = DbTable.of();
	public final Reviews:DbTable<SimpReview> = DbTable.of();

	public function new(configuration:DatabaseConfiguration) {
		super(configuration);
	}

	// Per-table configuration lives in the fluent builder.
	override function Configure(schema:SchemaSnapshot):Void {
		schema.Entity(SimpReview)
			.Column(r -> r.id).PrimaryKey(null, true, "PK_reviews")
			.Table.Check("CK_reviews_rating", r -> r.rating >= 1 && r.rating <= 5);
	}
}
