package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `CodeQueryTranslateExceptionTests.cs`. What an expression that cannot become SQL says. Here a lambda is converted while compiling, so what C# raises at runtime is a compile error, and no test can catch one. */
class CodeQueryTranslateExceptionTests extends TestCase {
	static final Reason = "CodeQueryTranslateException: an untranslatable expression is refused while compiling here, not at runtime";

	function testAnUntranslatableExpression_NamesThePartThatFailed() {
		Assert.skip(Reason);
	}

	function testAnUntranslatableExpression_CarriesTheWholeExpressionItSitsIn() {
		Assert.skip(Reason);
	}

	function testAnUntranslatableExpression_PointsAtTheLineItWasWrittenOn() {
		Assert.skip(Reason);
	}

	function testAnUntranslatableExpression_KeepsTheReasonFirstAndTheRestUnder() {
		Assert.skip(Reason);
	}

	function testAnUntranslatableExpression_IsStillTheNotSupportedItAlwaysWas() {
		Assert.skip(Reason);
	}

	function testAnExpressionThatFailsWhole_QuotesItselfAsBoth() {
		Assert.skip(Reason);
	}
}
