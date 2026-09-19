package codequery.testing;

/**
	The LINQ the C# tests lean on — `OfType`, `Single`, `First`, `Any` — as statics reached with
	`using codequery.testing.Linq;`, so `constraints.ofType(DatabasePrimaryKeyConstraint)` reads as
	the C# does.
**/
class Linq {
	public static function ofType<T:{}, U>(items:Array<U>, cls:Class<T>):Array<T> {
		return [for (item in items) if (Std.isOfType(item, cls)) cast item];
	}

	public static function first<T>(items:Array<T>, predicate:T->Bool):T {
		for (item in items) {
			if (predicate(item)) {
				return item;
			}
		}
		return Assert.fail("Expected an item matching the predicate, found none");
	}

	public static function firstOrDefault<T>(items:Array<T>, predicate:T->Bool):Null<T> {
		for (item in items) {
			if (predicate(item)) {
				return item;
			}
		}
		return null;
	}

	public static function single<T>(items:Array<T>, ?predicate:T->Bool):T {
		final found = predicate == null ? items : items.filter(predicate);
		return Assert.single(found);
	}

	public static function any<T>(items:Array<T>, predicate:T->Bool):Bool {
		for (item in items) {
			if (predicate(item)) {
				return true;
			}
		}
		return false;
	}

	public static function count<T>(items:Array<T>, ?predicate:T->Bool):Int {
		return predicate == null ? items.length : items.filter(predicate).length;
	}

	public static function sorted(items:Array<String>):Array<String> {
		final copy = items.copy();
		copy.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return copy;
	}
}
