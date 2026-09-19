package suites;

import codequery.InlineFunction;
import codequery.Query;
import codequery.SqlDate;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.SqlTree;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/** Flattened into the product's own columns — supplier_name, supplier_country. */
class InlineSupplier {
	public var name:String = "";
	public var country:String = "";

	public function new() {}
}

@tableName("products")
class InlineFunctionProduct {
	public var id:Int = 0;
	public var name:String = "";
	public var priceCents:Int = 0;
	public var stock:Int = 0;
	public var releasedOn:SqlDate;
	public var supplier:InlineSupplier = new InlineSupplier();

	public function new() {}
}

/**
	`InlineFunctionTests.cs`. An `InlineFunction` is a piece of a query written as a Haxe function.
	It is not translated — it is expanded while the query is compiled, and the expression it returns
	takes the place of the call, so what is built is what writing that expression out by hand would
	give.

	The domain here is a catalogue: products with a price, a stock level and a release date.
**/
class InlineFunctionTests extends TestCase {
	// ---- the functions under test ---------------------------------------------------------------------

	/** Twice a number — the number being whatever the caller passes, column or value. */
	static function Double(value:Int):InlineFunction<Int> {
		return InlineFunction.create(() -> value * 2);
	}

	/** A name with its age marked on it. */
	static function AppendOld(value:String):InlineFunction<String> {
		return InlineFunction.create(() -> value + " (old)");
	}

	/** A constant: a function need take nothing at all. */
	static function Answer():InlineFunction<Int> {
		return InlineFunction.create(() -> 42);
	}

	/** What is left of a product's price after a discount worked out in Haxe. */
	static function Discounted(p:InlineFunctionProduct, percentOff:Int):InlineFunction<Float> {
		// Ordinary Haxe, run while the query is built: the query carries the number it worked out.
		final remaining = 100 - percentOff;

		return InlineFunction.create(() -> p.priceCents * remaining / 100);
	}

	static function InStock(p:InlineFunctionProduct):InlineFunction<Bool> {
		return InlineFunction.create(() -> p.stock > 0);
	}

	static function DoubleTwice(value:Int):InlineFunction<Int> {
		return InlineFunction.create(() -> Double(value).value * 2);
	}

	static function Blend(a:Int, b:Int, c:Int):InlineFunction<Int> {
		return InlineFunction.create(() -> a + b + c);
	}

	static function Describe(s:InlineSupplier):InlineFunction<String> {
		return InlineFunction.create(() -> s.name + " of " + s.country);
	}

	static function SupplierOf(p:InlineFunctionProduct):InlineFunction<String> {
		return InlineFunction.create(() -> p.supplier.country);
	}

	/** The percentage in `(priceCents * remaining) / 100`. */
	static function RemainingPercent(discounted:ISqlExpression):ISqlExpression {
		return discounted.binary(Divide).Left.binary(Multiply).Right;
	}

	// ---- what it builds -------------------------------------------------------------------------------

	/**
		The call is replaced by what the function returns, so the query says what writing it in place
		would: the same arithmetic, over the same column. The one difference is what the function
		computed — a local it captured, so the query binds it rather than writing it in.
	**/
	function testAFunction_BuildsWhatItWouldHaveBeenWrittenAs() {
		final divided = Query.select(InlineFunctionProduct).Select(p -> {cheap: Discounted(p, 10)}).ToExpression().selectionAt(0).binary(Divide);
		divided.Right.value(100);

		final multiplied = divided.Left.binary(Multiply);
		multiplied.Left.column("priceCents");
		multiplied.Right.bound(90);
	}

	/** A column may be passed in: it arrives as the column, not as a value read off a row. */
	function testAColumn_CanBePassedIn() {
		Query.select(InlineFunctionProduct).Select(p -> {twiceTheStock: Double(p.stock)}).ToExpression().selectionAt(0).comparison("stock", Multiply, 2);
	}

	function testAStringColumn_CanBePassedIn() {
		final concat = Query.select(InlineFunctionProduct).Select(p -> {marked: AppendOld(p.name)}).ToExpression().selectionAt(0).call(SqlFunctions.Concat);
		Assert.count(2, concat.Arguments);

		concat.Arguments[0].column("name");
		concat.Arguments[1].value(" (old)");
	}

	/** The same function serves a plain value just as well — it is only an expression either way. */
	function testAValue_CanBePassedInsteadOfAColumn() {
		final doubled = Query.select(InlineFunctionProduct).Select(p -> {twenty: Double(10)}).ToExpression().selectionAt(0).binary(Multiply);

		doubled.Left.value(10);
		doubled.Right.value(2);
	}

	function testAFunction_NeedTakeNothing() {
		Query.select(InlineFunctionProduct).Select(p -> {answer: Answer()}).ToExpression().selectionAt(0).value(42);
	}

	/** The row it is given is the row the query reads — the statement's own first source. */
	function testTheRowItIsGiven_IsTheQuerysOwnRow() {
		final select = Query.select(InlineFunctionProduct).Select(p -> {cheap: Discounted(p, 25)}).ToExpression();

		final priced = select.selectionOf("cheap").binary().Left.binary();
		final column = priced.Left.column("priceCents");
		final source = Assert.isType(column.Source, ParameterSqlSource);
		Assert.equals(0, source.Index);
		Assert.equals("t0", new codequery.sqldrivers.SqlTranslator().ToSql(select).split(" FROM ")[1].split(" ")[2]);
	}

	/**
		What the function computes in Haxe lands in the query as the number it worked out, not as a
		decision the database has to make.
	**/
	function testWhatItComputesInCSharp_ReachesTheQueryAsAValue() {
		RemainingPercent(Query.select(InlineFunctionProduct).Select(p -> {cheap: Discounted(p, 10)}).ToExpression().selectionAt(0)).value(90);
		RemainingPercent(Query.select(InlineFunctionProduct).Select(p -> {cheap: Discounted(p, 50)}).ToExpression().selectionAt(0)).value(50);
	}

	/** A function stands anywhere its value does — including a predicate. */
	function testAFunction_WorksInAPredicate() {
		final select = Query.select(InlineFunctionProduct).Where(p -> InStock(p)).ToExpression();

		select.whereClause().comparison("stock", GreaterThan, 0);
	}

	/** One function, both branches of a CASE — the reason for naming a piece of a query at all. */
	function testOneFunction_ServesBothBranchesOfACase() {
		final branches = Query.select(InlineFunctionProduct).Select(p -> {
			price: p.releasedOn.getFullYear() < 2020 ? Discounted(p, 50) : Discounted(p, 10)
		}).ToExpression().selectionAt(0).caseWhen();
		Assert.count(1, branches.Branches);

		final when = branches.Branches[0].When.binary(LessThan);
		when.Left.call(SqlFunctions.Year).Arguments[0].column("releasedOn");
		when.Right.value(2020);

		// Each call was expanded where it stands, so the two branches carry their own numbers.
		RemainingPercent(branches.Branches[0].Then).value(50);
		RemainingPercent(branches.Otherwise).value(90);
	}

	/** A function may call another: each call is expanded where it stands. */
	function testAFunction_CanUseAnother() {
		final outer = Query.select(InlineFunctionProduct).Select(p -> {quadruple: DoubleTwice(p.stock)}).ToExpression().selectionAt(0).binary(Multiply);

		outer.Right.value(2);
		outer.Left.comparison("stock", Multiply, 2);
	}

	/** Nesting works the other way too: a function's argument may be another function's result. */
	function testAFunctionsResult_CanBeAnothersArgument() {
		SqlTree.assertSame(
			Query.select(InlineFunctionProduct).Select(p -> {marked: p.name + " (old)"}).ToExpression().selectionAt(0),
			Query.select(InlineFunctionProduct).Select(p -> {marked: AppendOld(p.name)}).ToExpression().selectionAt(0));
	}

	// ---- what it refuses ------------------------------------------------------------------------------

	/** Reading the row outside the lambda cannot work — there is no row while the query is being built. */
	function testReadingTheRowOutsideTheLambda_SaysWhy() {
		Assert.skip("an inline function reading the row outside InlineFunction.create is refused while compiling, which a test cannot catch");
	}

	/** Outside a query it is not a value: evaluating one says so. */
	function testUsedOutsideAQuery_ItThrows() {
		final answer = Answer();

		Assert.throws(() -> {
			final value:Int = answer;
		});
	}

	// ---- which arguments are carried, and which are computed --------------------------------------------

	/** Any argument that reads the row is carried whole — whatever was written around the column. */
	function testAnyArgumentReadingTheRow_IsCarriedWhole() {
		final outer = Query.select(InlineFunctionProduct).Select(p -> {x: Double(p.stock * 3)}).ToExpression().selectionAt(0).binary(Multiply);

		outer.Right.value(2);
		outer.Left.comparison("stock", Multiply, 3);
	}

	/** The two kinds mix freely in one call. */
	function testCarriedAndComputedArguments_MixInOneCall() {
		final sum = Query.select(InlineFunctionProduct).Select(p -> {x: Blend(p.stock, 3 + 4, p.priceCents)}).ToExpression().selectionAt(0).binary(Add);

		sum.Right.column("priceCents");

		// The middle argument reads nothing of the row, so it arrives as the 7 it works out to.
		sum.Left.comparison("stock", Add, 7);
	}

	/** A row-reading argument used in Haxe rather than in the expression would be used on nothing. */
	function testARowArgumentUsedOutsideTheExpression_IsRefused() {
		Assert.skip("a row-reading argument not used inside InlineFunction.create is refused while compiling, which a test cannot catch");
	}

	// ---- nested members ---------------------------------------------------------------------------------

	/** A nested member reads the row as much as a top-level one does, so it is carried the same. */
	function testANestedMember_CanBePassedIn() {
		final shared = Query.select(InlineFunctionProduct).Select(p -> {marked: AppendOld(p.supplier.name)}).ToExpression().selectionAt(0);

		shared.call(SqlFunctions.Concat).Arguments[0].column("supplier_name");
		SqlTree.assertSame(Query.select(InlineFunctionProduct).Select(p -> {marked: p.supplier.name + " (old)"}).ToExpression().selectionAt(0), shared);
	}

	/** The object itself can be passed, and its members read inside the expression. */
	function testANestedObject_CanBePassedIn_AndItsMembersRead() {
		SqlTree.assertSame(
			Query.select(InlineFunctionProduct).Select(p -> {from: p.supplier.name + " of " + p.supplier.country}).ToExpression().selectionAt(0),
			Query.select(InlineFunctionProduct).Select(p -> {from: Describe(p.supplier)}).ToExpression().selectionAt(0));
	}

	/** The row itself carries its nested members with it. */
	function testARowArgument_CarriesItsNestedMembers() {
		Query.select(InlineFunctionProduct).Select(p -> {from: SupplierOf(p)}).ToExpression().selectionAt(0).column("supplier_country");
	}

	// ---- standing in for its value ----------------------------------------------------------------------

	/** A projection into a shape of its own: the function fills the member as the expression would. */
	function testAFunction_FillsAMemberOfAProjectedType() {
		final shared = Query.select(InlineFunctionProduct).Select(p -> {name: AppendOld(p.name), twice: Double(p.stock)}).ToExpression();
		final byHand = Query.select(InlineFunctionProduct).Select(p -> {name: p.name + " (old)", twice: p.stock * 2}).ToExpression();

		SqlTree.assertSame(byHand, shared);
		shared.selectionOf("name").call(SqlFunctions.Concat).Arguments[0].column("name");
	}

	/** Where an operand's type is what Haxe reads, the conversion cannot help; `.value` names it. */
	function testValue_LetsAGenericArgumentBeInferred() {
		final branches = Query.select(InlineFunctionProduct).Select(p -> {
			price: p.stock > 0 ? Discounted(p, 10).value : Discounted(p, 50).value
		}).ToExpression().selectionAt(0).caseWhen();
		Assert.count(1, branches.Branches);

		branches.Branches[0].When.comparison("stock", GreaterThan, 0);
		RemainingPercent(branches.Branches[0].Then).value(90);
		RemainingPercent(branches.Otherwise).value(50);
	}

	function testValue_BuildsTheSameAsTheFunctionItself() {
		SqlTree.assertSame(
			Query.select(InlineFunctionProduct).Select(p -> {x: Double(p.stock)}).ToExpression().selectionAt(0),
			Query.select(InlineFunctionProduct).Select(p -> {x: Double(p.stock).value}).ToExpression().selectionAt(0));
	}

	function testValue_ReadOutsideAQuery_Throws() {
		Assert.throws(() -> Answer().value);
	}
}
