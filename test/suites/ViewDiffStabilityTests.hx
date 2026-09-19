package suites;

import codequery.DbTable;
import codequery.DbView;
import codequery.Query;
import codequery.migrations.SchemaBuilder;
import codequery.migrations.SchemaChange;
import codequery.migrations.SchemaDiff;
import codequery.migrations.SchemaSnapshot;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** C#'s `BookDecimal`; the port has no decimal, so the column that changes type is an Int here… */
@tableName("Book")
class StabilityBookInt {
	public var id:Int = 0;
	public var price:Int = 0;
	public var title:String = "";

	public function new() {}
}

/** …and a Float there. */
@tableName("Book")
class StabilityBookFloat {
	public var id:Int = 0;
	public var price:Float = 0;
	public var title:String = "";

	public function new() {}
}

class StabilityDbInt {
	public final Books:DbTable<StabilityBookInt> = DbTable.of();
	public final V:DbView<StabilityBookInt>;

	public function new() {
		V = DbView.of(Books.From().OrderBy(x -> x.price), "v_expensive_books");
	}
}

class StabilityDbFloat {
	public final Books:DbTable<StabilityBookFloat> = DbTable.of();
	public final V:DbView<StabilityBookFloat>;

	public function new() {
		V = DbView.of(Books.From().OrderBy(x -> x.price), "v_expensive_books");
	}
}

/**
	`ViewDiffStabilityTests.cs`: a view references columns by name, so its identity must not depend
	on the type of those columns: changing a referenced column's type is a table change only, never
	a view recreation.
**/
class ViewDiffStabilityTests extends TestCase {
	function testReferencedColumnTypeChange_IsTableChangeOnly_NotViewRecreation() {
		final before = SchemaBuilder.Of(new StabilityDbInt());
		final stored = SchemaSnapshot.FromYaml(SchemaSnapshot.ToYaml(before));

		final after = SchemaBuilder.Of(new StabilityDbFloat());

		final diff = SchemaDiff.Between(stored, after);

		// The price column's type changed, and nothing else — the view is unchanged.
		switch Assert.single(diff) {
			case AlterColumn("Book", _, to): Assert.equals("price", to.Name);
			case other: Assert.fail('Expected only the column to change, got $other');
		}
	}

	function testUnchangedSchema_RoundTrips_WithNoRoutineChange() {
		final db = SchemaBuilder.Of(new StabilityDbInt());
		final stored = SchemaSnapshot.FromYaml(SchemaSnapshot.ToYaml(db));

		Assert.empty(SchemaDiff.Between(stored, db));
	}
}
