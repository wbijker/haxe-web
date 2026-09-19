package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("parts")
class ConstructorPart {
	public var id:Int = 0;
	public var name:String = "";
	public var price:Float = 0;

	public function new() {}
}

/** A row type that says what it holds through its constructor. */
class ConstructorListing {
	public final id:Int;
	public final name:String;
	public var price:Float = 0;

	public function new(id:Int, name:String) {
		this.id = id;
		this.name = name;
	}
}

/** C#'s `record Summary(int Id, string Name)`: a constructor and nothing else. */
class ConstructorSummary {
	public final id:Int;
	public final name:String;

	public function new(id:Int, name:String) {
		this.id = id;
		this.name = name;
	}
}

/**
	`ProjectionConstructorTests.cs`: a projection into a type that has a real constructor. Its
	arguments are the members, named as the constructor names them.
**/
class ProjectionConstructorTests extends TestCase {
	function testTheConstructorArgumentsAreColumns() {
		final select = Query.select(ConstructorPart)
			.Select(p -> new ConstructorListing(p.id, p.name))
			.ToExpression();

		Assert.equals("parts", select.selectTableName());
		Assert.equals(["id", "name"], select.memberNames());
		select.selectionOf("id").column("id");
		select.selectionOf("name").column("name");
	}

	function testAndSoAreTheBindingsBesideThem() {
		Assert.skip("object initializer beside a constructor: Haxe has no `new T(…) { X = … }`");
	}

	function testARecordProjects() {
		final select = Query.select(ConstructorPart)
			.Select(p -> new ConstructorSummary(p.id, p.name))
			.ToExpression();

		Assert.equals(["id", "name"], select.memberNames());
		select.selectionOf("id").column("id");
		select.selectionOf("name").column("name");
	}

	function testItComesBackWhole() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
