package codequery.testing;

/** A test that did not hold. */
class AssertionFailure {
	public final Message:String;

	public function new(message:String) {
		this.Message = message;
	}

	public function toString():String {
		return Message;
	}
}

/** A test that stands aside, and says why — the port's counterpart of xunit's SkippableFact. */
class Skipped {
	public final Reason:String;

	public function new(reason:String) {
		this.Reason = reason;
	}
}

/** What a test says about what it found. Modelled on xunit's `Assert`, since that is what the C# tests use. */
class Assert {
	public static function fail(message:String):Dynamic {
		throw new AssertionFailure(message);
	}

	/** Stands the test aside: the feature it tests is one this port does not have. */
	public static function skip(reason:String):Dynamic {
		throw new Skipped(reason);
	}

	public static function isTrue(condition:Bool, ?message:String):Void {
		if (!condition) {
			fail(message == null ? "Expected true" : message);
		}
	}

	public static function isFalse(condition:Bool, ?message:String):Void {
		if (condition) {
			fail(message == null ? "Expected false" : message);
		}
	}

	public static function notNull(value:Dynamic, ?message:String):Void {
		if (value == null) {
			fail(message == null ? "Expected a value, got null" : message);
		}
	}

	public static function isNull(value:Dynamic, ?message:String):Void {
		if (value != null) {
			fail(message == null ? 'Expected null, got ${Std.string(value)}' : message);
		}
	}

	public static function equals(expected:Dynamic, actual:Dynamic, ?message:String):Void {
		if (!Same(expected, actual)) {
			fail((message == null ? "" : message + ": ") + 'expected ${Show(expected)}, got ${Show(actual)}');
		}
	}

	public static function notEqual(expected:Dynamic, actual:Dynamic, ?message:String):Void {
		if (Same(expected, actual)) {
			fail((message == null ? "" : message + ": ") + 'expected something other than ${Show(expected)}');
		}
	}

	public static function contains(needle:String, haystack:String):Void {
		if (haystack == null || haystack.indexOf(needle) < 0) {
			fail('Expected to find "$needle" in:\n$haystack');
		}
	}

	public static function doesNotContain(needle:String, haystack:String):Void {
		if (haystack != null && haystack.indexOf(needle) >= 0) {
			fail('Did not expect to find "$needle" in:\n$haystack');
		}
	}

	public static function startsWith(prefix:String, text:String):Void {
		if (text == null || !StringTools.startsWith(text, prefix)) {
			fail('Expected "$text" to start with "$prefix"');
		}
	}

	public static function endsWith(suffix:String, text:String):Void {
		if (text == null || !StringTools.endsWith(text, suffix)) {
			fail('Expected "$text" to end with "$suffix"');
		}
	}

	public static function matches(pattern:EReg, text:String):Void {
		if (text == null || !pattern.match(text)) {
			fail('Expected "$text" to match the pattern');
		}
	}

	public static function empty(items:Array<Dynamic>, ?message:String):Void {
		if (items == null || items.length != 0) {
			fail(message == null ? 'Expected no items, got ${items == null ? "null" : Std.string(items.length)}' : message);
		}
	}

	public static function single<T>(items:Array<T>):T {
		if (items == null || items.length != 1) {
			fail('Expected exactly one item, got ${items == null ? "null" : Std.string(items.length)}');
		}
		return items[0];
	}

	public static function count(expected:Int, items:Array<Dynamic>):Void {
		if (items == null || items.length != expected) {
			fail('Expected $expected items, got ${items == null ? "null" : Std.string(items.length)}');
		}
	}

	public static function inRange(value:Float, low:Float, high:Float):Void {
		if (value < low || value > high) {
			fail('Expected $value to be within [$low, $high]');
		}
	}

	/** The value as `T`, or a failure naming what it was instead. */
	public static function isType<T:{}>(value:Dynamic, cls:Class<T>, ?message:String):T {
		final typed = Std.downcast(value, cls);
		if (typed == null) {
			final actual = value == null ? "null" : Type.getClassName(Type.getClass(value));
			fail((message == null ? "" : message + ": ")
				+ 'expected ${Type.getClassName(cls)}, got $actual');
		}
		return typed;
	}

	/** Runs `action` and answers with what it threw — failing if it threw nothing. */
	public static function throws(action:Void->Void, ?message:String):Dynamic {
		try {
			action();
		} catch (e:Skipped) {
			throw e;
		} catch (e:Dynamic) {
			return e;
		}
		return fail(message == null ? "Expected an exception" : message);
	}

	/** The message of what `action` threw, which is where most of the tests look. */
	public static function throwsMessage(action:Void->Void):String {
		final thrown = throws(action);
		return Std.isOfType(thrown, String) ? thrown : Std.string(thrown);
	}

	static function Same(a:Dynamic, b:Dynamic):Bool {
		if (a == null || b == null) {
			return a == b;
		}
		if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
			final x:Array<Dynamic> = a;
			final y:Array<Dynamic> = b;
			if (x.length != y.length) {
				return false;
			}
			for (index in 0...x.length) {
				if (!Same(x[index], y[index])) {
					return false;
				}
			}
			return true;
		}
		// Enum values compare by structure; numbers of either kind compare by value.
		if (Reflect.isEnumValue(a) && Reflect.isEnumValue(b)) {
			return Type.enumEq(a, b);
		}
		if (Std.isOfType(a, Float) && Std.isOfType(b, Float)) {
			return (a : Float) == (b : Float);
		}
		return a == b || Std.string(a) == Std.string(b);
	}

	static function Show(value:Dynamic):String {
		return Std.isOfType(value, String) ? '"$value"' : Std.string(value);
	}
}
