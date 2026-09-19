package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/**
	`QueryDelegateTests.cs` — the three kinds of lambda a query takes, held rather than written: a
	static holding one, or a function that hands one back.
**/
class QueryDelegateTests extends TestCase {
	static final title = (b:DelegateBook) -> b.title;
	static final dear = (b:DelegateBook) -> b.price > 20;
	static final byPrice = (b:DelegateBook) -> b.price;
	static final sameAuthor = (a:DelegateBook, b:DelegateBook) -> a.authorId == b.authorId && a.id < b.id;
	static final pair = (a:DelegateBook, b:DelegateBook) -> {first: a.title, second: b.title};

	/** A projection handed over as a factory, for a query built more than once. */
	static function deferredTitle() {
		return (b:DelegateBook) -> b.title;
	}

	/** Which of the statement's sources a column belongs to — what the C# reads as its alias. */
	static function boundTo(column:ColumnSqlExpression, index:Int) {
		Assert.equals(index, Assert.isType(column.Source, ParameterSqlSource).Index, "source position");
	}

	function testAProjectionCanBeHeld() {
		final select = Query.select(DelegateBook).Select(title).ToExpression();

		Assert.equals("books", select.selectTableName());
		select.selectionAt(0).column("title");
	}

	function testSoCanACondition() {
		final select = Query.select(DelegateBook).Where(dear).Select(b -> {id: b.id}).ToExpression();

		select.whereClause().comparison("price", GreaterThan, 20);
	}

	function testAndAKeySelector() {
		final select = Query.select(DelegateBook).OrderByDesc(byPrice).Select(b -> {id: b.id}).ToExpression();

		select.orderBy().Expression.column("price");
		Assert.isFalse(select.orderBy().Ascending);
	}

	function testTheyCarryAcrossWidths() {
		final select = Query.select(DelegateBook)
			.InnerJoin(Query.table(DelegateBook), sameAuthor)
			.Select(pair)
			.ToExpression();

		final joined = select.joinOfType(Inner).Source;
		Assert.equals("books", joined.tableName());

		final and = select.joinOnBinary().binary(And);
		final byAuthor = and.Left.columnComparison("authorId", Equal, "authorId");
		boundTo(byAuthor.Left.column(), 0);
		boundTo(byAuthor.Right.column(), 1);
		and.Right.columnComparison("id", LessThan, "id");

		boundTo(select.selectionOf("first").column("title"), 0);
		boundTo(select.selectionOf("second").column("title"), 1);
	}

	function testAProjectionCanBeDeferred() {
		final select = Query.select(DelegateBook).Select(deferredTitle).ToExpression();

		select.selectionAt(0).column("title");
	}

	function testCountingRowsAndCountingValuesAreSaidApart() {
		final select = Query.select(DelegateBook)
			.GroupBy(b -> b.authorId)
			.SelectAggregation(g -> {
				books: g.count(),
				dear: g.count().filter(b -> b.price > 20),
				priced: g.countValues(b -> b.price),
				prices: g.countDistinct(b -> b.price),
			})
			.ToExpression();

		// Counting rows: no argument, so nothing about a row can leave it out.
		final books = select.selectionOf("books").aggregate(Count);
		Assert.isNull(books.Argument);
		Assert.isNull(books.Filter);
		Assert.isFalse(books.Distinct);

		// Counting rows that pass a test: still the rows, narrowed.
		final dear = select.selectionOf("dear").aggregate(Count);
		Assert.isNull(dear.Argument);
		dear.Filter.comparison("price", GreaterThan, 20);

		// Counting values: the column is the argument, so a null in it is not counted.
		final priced = select.selectionOf("priced").aggregate(Count);
		priced.Argument.column("price");
		Assert.isFalse(priced.Distinct);

		// Counting different values.
		final prices = select.selectionOf("prices").aggregate(Count);
		prices.Argument.column("price");
		Assert.isTrue(prices.Distinct);
	}

	function testCountingValuesTakesAFilterToo() {
		final select = Query.select(DelegateBook)
			.GroupBy(b -> b.authorId)
			.SelectAggregation(g -> {priced: g.countValues(b -> b.price).filter(b -> b.price > 20)})
			.ToExpression();

		final priced = select.selectionOf("priced").aggregate(Count);
		priced.Argument.column("price");
		priced.Filter.comparison("price", GreaterThan, 20);
	}
}

@tableName("books")
class DelegateBook {
	public var id:Int = 0;
	public var title:String = "";
	public var price:Float = 0;
	public var authorId:Int = 0;

	public function new() {}
}
