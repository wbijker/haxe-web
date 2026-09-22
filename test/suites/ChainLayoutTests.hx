package suites;

import codequery.php.ChainLayout;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`ChainLayout` — the generated PHP's chains of calls laid out one call a line. This port's own:
	the C# has no generated code to lay out.
**/
class ChainLayoutTests extends TestCase {
	function testAChainOfCallsBreaksBeforeEachCallPastTheFirstArrow() {
		Assert.equals(
			"\t\tMain::$db->Bookings\n\t\t\t->Update()\n\t\t\t->WhereCondition(Expr::gt($a, 1))\n\t\t\t->Execute();",
			ChainLayout.Reflow("\t\tMain::$db->Bookings->Update()->WhereCondition(Expr::gt($a, 1))->Execute();"));
	}

	function testAFieldAndOneCallStayOnTheirLine() {
		final line = "\t\t$rows = $this->Configuration->Fetch($this->CountExpression());";
		Assert.equals(line, ChainLayout.Reflow(line));
	}

	function testAnArrowInsideAnArgumentIsNotAChainOfItsOwn() {
		final line = "\t\techo(\\Std::string(\"x \" . ($repriced->Execute()->foo()??'null')));";
		Assert.equals(line, ChainLayout.Reflow(line));
	}

	function testArrowsInsideStringsAreLeftAlone() {
		final line = "\t\t$s = \"a->b()->c()\" . '->d()->e()';";
		Assert.equals(line, ChainLayout.Reflow(line));
	}

	function testTwoChainsOnOneLineAreLaidOutEach() {
		Assert.equals(
			"\t$a->b()\n\t\t->c() + $d->e()\n\t\t->f();",
			ChainLayout.Reflow("\t$a->b()->c() + $d->e()->f();"));
	}

	function testAClosureInTheChainHangsFromItsOwnLine() {
		final generated = [
			"\t\t$rows = Main::$db->Bookings->From()->Where(function ($b) {",
			"\t\t\treturn Expr::gt($b->price, 1);",
			"\t\t})->Fetch();"
		].join("\n");
		final laidOut = [
			"\t\t$rows = Main::$db->Bookings",
			"\t\t\t->From()",
			"\t\t\t->Where(function ($b) {",
			"\t\t\t\treturn Expr::gt($b->price, 1);",
			"\t\t\t})",
			"\t\t\t->Fetch();"
		].join("\n");
		Assert.equals(laidOut, ChainLayout.Reflow(generated));
	}

	function testAStatementSpreadOverLinesWithoutAChainIsLeftAlone() {
		final lines = "\t\tfoo(\n\t\t\t$a,\n\t\t\t$b\n\t\t);";
		Assert.equals(lines, ChainLayout.Reflow(lines));
	}

	function testPositionDirectivesAndCommentsAreNotCode() {
		final line = "\t\t#src/Main.hx:19: lines 19-22 ->a()->b()";
		Assert.equals(line, ChainLayout.Reflow(line));
	}
}
