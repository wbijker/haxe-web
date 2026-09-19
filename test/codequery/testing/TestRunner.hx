package codequery.testing;

import codequery.testing.TestCase;

/**
	Runs suites and says what happened, in enough detail to act on.

	Pass a suite name, or part of one, to run only those; pass `-v` to see every test rather than
	only the ones that did not pass.
**/
class TestRunner {
	var passed = 0;
	var failed = 0;
	var skipped = 0;
	var errored = 0;
	final failures:Array<String> = [];
	final reasons = new Map<String, Int>();

	public function new() {}

	public function runAll(suites:Array<TestCase>, ?filter:String, verbose:Bool = false):Bool {
		for (suite in suites) {
			final name = Type.getClassName(Type.getClass(suite)).split(".").pop();
			if (filter != null && name.toLowerCase().indexOf(filter.toLowerCase()) < 0) {
				continue;
			}
			runSuite(suite, name, verbose);
		}
		report();
		return failed == 0 && errored == 0;
	}

	function runSuite(suite:TestCase, name:String, verbose:Bool):Void {
		final results = [for (test in suite.tests()) {test: test, result: suite.run(test)}];
		var line = '$name: ';
		for (r in results) {
			switch r.result {
				case Passed:
					passed++;
					line += ".";
				case SkippedFor(reason):
					skipped++;
					line += "s";
					reasons.set(reason, (reasons.exists(reason) ? reasons.get(reason) : 0) + 1);
				case Failed(message):
					failed++;
					line += "F";
					failures.push('FAIL $name.${r.test}\n    $message');
				case Errored(message):
					errored++;
					line += "E";
					failures.push('ERROR $name.${r.test}\n    $message');
			}
		}
		Sys.println(line);
		if (verbose) {
			for (r in results) {
				Sys.println('    ${r.test}: ${Std.string(r.result)}');
			}
		}
	}

	function report():Void {
		Sys.println("");
		for (failure in failures) {
			Sys.println(failure);
		}
		if (reasons.keys().hasNext()) {
			Sys.println("Skipped, by reason:");
			final sorted = [for (reason in reasons.keys()) reason];
			sorted.sort((a, b) -> reasons.get(b) - reasons.get(a));
			for (reason in sorted) {
				Sys.println('  ${reasons.get(reason)}  $reason');
			}
		}
		Sys.println("");
		Sys.println('$passed passed, $failed failed, $errored errored, $skipped skipped');
	}
}
