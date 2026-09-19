package suites;

import codequery.testing.TestCase;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Every suite in this folder, found by looking rather than listed.

	A suite is a file here whose class extends `TestCase`. Nothing registers it: the folder is read
	while compiling, so adding a suite is adding a file, and two people adding suites never touch
	the same line.
**/
class Suites {
	public static macro function all():Expr {
		final folder = Context.resolvePath("suites");
		final names = [
			for (file in sys.FileSystem.readDirectory(folder))
				if (StringTools.endsWith(file, ".hx") && file != "Suites.hx") file.substr(0, file.length - 3)
		];
		names.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));

		final made = [for (name in names) {
			final path:TypePath = {pack: ["suites"], name: name};
			macro(new $path() : codequery.testing.TestCase);
		}];
		return macro $a{made};
	}
}
