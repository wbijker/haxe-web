package codequery.testing;

import codequery.testing.Assert;

/**
	A suite of tests: every method named `test…` is one.

	The C# suite is xunit, where a test is a method with `[Fact]` on it; here it is a method with a
	name that says so, found by looking rather than by attribute.
**/
class TestCase {
	public function new() {}

	/** Before each test. */
	public function setUp():Void {}

	/** After each test, whether or not it held. */
	public function tearDown():Void {}

	/** The tests, in declaration order as far as the target keeps it. */
	public function tests():Array<String> {
		final names = [for (name in Type.getInstanceFields(Type.getClass(this)))
			if (IsTest(name) && Reflect.isFunction(Reflect.field(this, name))) name];
		names.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return names;
	}

	/** `testSomething` is a test; `tests` is this method. */
	static function IsTest(name:String):Bool {
		if (!StringTools.startsWith(name, "test") || name.length == 4) {
			return false;
		}
		final next = name.charAt(4);
		return next == "_" || next.toUpperCase() == next;
	}

	/** Runs one, and answers with what happened. */
	public function run(name:String):TestResult {
		setUp();
		try {
			Reflect.callMethod(this, Reflect.field(this, name), []);
			tearDown();
			return Passed;
		} catch (skipped:Skipped) {
			tearDown();
			return SkippedFor(skipped.Reason);
		} catch (failure:AssertionFailure) {
			tearDown();
			return Failed(failure.Message);
		} catch (e:Dynamic) {
			tearDown();
			final where = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
			return Errored(Std.string(e) + where);
		}
	}
}

enum TestResult {
	Passed;
	SkippedFor(reason:String);
	Failed(message:String);
	Errored(message:String);
}
