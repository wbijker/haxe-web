package suites;

import codequery.DbTable;
import codequery.InsertStrategy;
import codequery.Query;
import codequery.queries.InsertRefused;
import codequery.sqlexpressions.InsertExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** The entity `InsertValidationTests.cs` declares: a person whose columns constrain something. */
@tableName("person")
class Person {
	public var id:Int = 0;

	// A string is a nullable column unless the entity says otherwise, so NOT NULL is stated.
	@columnMaxLength(10)
	@columnNullable(false)
	public var name:String = "";

	public var nickname:Null<String>;

	@dbColumnPrecision(5, 2)
	public var rate:Float = 0;

	public var rank:Int = 0;

	public function new() {}
}

/**
	`InsertValidationTests.cs`.

	A value that will not fit its column is refused before it is sent, naming the member and the
	row — rather than by the database in terms of the constraint it broke. C# gets as far as a
	connection that then fails; the port builds the statement and stops there, so "not refused"
	is "builds without throwing".
**/
class InsertValidationTests extends TestCase {
	static final people:DbTable<Person> = Query.table(Person, "person");

	static function Checked():InsertStrategy {
		final strategy = new InsertStrategy();
		strategy.ValidationCheck = true;
		return strategy;
	}

	static function Valid():Person {
		final person = new Person();
		person.name = "Ada";
		person.nickname = null;
		person.rate = 12.50;
		person.rank = 3;
		return person;
	}

	static function Repeat(char:String, count:Int):String {
		return [for (_ in 0...count) char].join("");
	}

	static function Refusal(action:Void->Void):String {
		return Assert.isType(Assert.throws(action), InsertRefused).Message;
	}

	function testAStringLongerThanItsColumn() {
		final person = Valid();
		person.name = Repeat("x", 11);

		final message = Refusal(() -> people.Insert(person, Checked()));

		Assert.contains("table     person", message);
		Assert.contains("column    name (VarChar(10)", message);
		Assert.contains("property  Person.name", message);
		Assert.contains("value     '", message);
		Assert.contains("reason", message);
		Assert.contains("11 characters and the column holds 10", message);
	}

	function testAStringExactlyItsColumnIsFine() {
		final person = Valid();
		person.name = Repeat("x", 10);

		// Nothing about the length stops it.
		Assert.notNull(people.Insert(person, Checked()));
	}

	function testADecimalWithTooManyDigitsBeforeThePoint() {
		final person = Valid();
		person.rate = 1234.5; // DECIMAL(5, 2) holds three digits before the point

		final message = Refusal(() -> people.Insert(person, Checked()));

		Assert.contains("table     person", message);
		Assert.contains("column    rate (Decimal(5, 2)", message);
		Assert.contains("value     1234.5", message);
		Assert.contains("DECIMAL(5, 2), which holds 3 digits", message);
	}

	/** The fraction is the database's to round; only what is left of the point can overflow. */
	function testADecimalWithTooManyDigitsAfterThePointIsFine() {
		final person = Valid();
		person.rate = 12.3456;

		Assert.notNull(people.Insert(person, Checked()));
	}

	function testNullIntoAColumnThatDoesNotTakeIt() {
		final person = Valid();
		person.name = null;

		final message = Refusal(() -> people.Insert(person, Checked()));

		Assert.contains("table     person", message);
		Assert.contains("column    name (VarChar(10), NOT NULL)", message);
		Assert.contains("value     null", message);
		Assert.contains("does not take null", message);
	}

	function testNullIntoAColumnThatDoes() {
		Assert.notNull(people.Insert(Valid(), Checked()));
	}

	/** Which row it was, because "too long" over twenty thousand rows is not an answer. */
	function testItNamesTheRow() {
		final rows = [for (_ in 0...5) Valid()];
		rows[3].name = Repeat("x", 40);

		final message = Refusal(() -> people.InsertMany(rows, Checked()));

		Assert.contains("(row 3 of 5)", message);
	}

	/** A value long enough to bury the message is cut, and says how long it really was. */
	function testALongValueIsCutDown() {
		final person = Valid();
		person.name = Repeat("x", 500);

		final message = Refusal(() -> people.Insert(person, Checked()));

		Assert.contains("…' (500 characters)", message);
		Assert.isTrue(message.length < 700, "the message should not carry the whole value");
	}

	function testOneRowIsNotNumbered() {
		final person = Valid();
		person.name = Repeat("x", 40);

		Assert.doesNotContain("row ", Refusal(() -> people.Insert(person, Checked())));
	}

	function testAnIntegerOutsideItsColumn() {
		Assert.skip("SchemaInspector/SmallInt: Haxe has no short, so no column is narrower than the field it reads");
	}

	/** Off by default: the database is what checks, and checking twice costs a pass over every row. */
	function testWithoutAskingForIt_NothingIsChecked() {
		final person = Valid();
		person.name = Repeat("x", 500);

		// Not refused here — it builds, and would get as far as the connection.
		final statement:InsertExpression = people.Insert(person);
		Assert.notNull(statement);
	}

	function testAValidRowSaysNothing() {
		final rows = [for (i in 1...101) {
			final person = new Person();
			person.name = 'n$i';
			person.nickname = i % 2 == 0 ? null : "nick";
			person.rate = 99.99;
			person.rank = i;
			person;
		}];

		Assert.notNull(people.InsertMany(rows, Checked()));
	}
}
