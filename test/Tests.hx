import codequery.testing.TestRunner;

/**
	The C# suite, ported: one Haxe suite per C# test class, listed in `suites.Suites`.

	`haxe test.hxml` runs them all. On the eval target `Sys.args()` is the compiler's own command
	line, so a filter is given as `TEST=Select haxe test.hxml`, and `TEST_VERBOSE=1` lists every
	test rather than only the ones that did not pass.
**/
class Tests {
	static function main() {
		final filter = Sys.getEnv("TEST");
		final verbose = Sys.getEnv("TEST_VERBOSE") != null;

		final ok = new TestRunner().runAll(suites.Suites.all(), filter, verbose);
		Sys.exit(ok ? 0 : 1);
	}
}
