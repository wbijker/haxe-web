package codequery.testing;

/**
	An expression tree written out in one canonical form, so that two built different ways can be
	compared as wholes — the C# `SqlTreeSerializer` behind `AssertSameStructure`.

	Reflective, so a new kind of node needs nothing added here: a class is its name and its fields
	in name order, an enum is itself, and a list is its items.
**/
class SqlTree {
	public static function Canonical(value:Dynamic):String {
		return Write(value, 0);
	}

	/** Fails unless the two trees read the same. */
	public static function assertSame(expected:Dynamic, actual:Dynamic):Void {
		Assert.equals(Canonical(expected), Canonical(actual));
	}

	static function Write(value:Dynamic, depth:Int):String {
		if (depth > 40) {
			return "…";
		}
		if (value == null) {
			return "null";
		}
		if (Std.isOfType(value, String)) {
			return '"$value"';
		}
		if (Std.isOfType(value, Bool) || Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return Std.string(value);
		}
		if (Std.isOfType(value, Array)) {
			final items:Array<Dynamic> = value;
			return "[" + items.map(item -> Write(item, depth + 1)).join(", ") + "]";
		}
		if (Std.isOfType(value, Date)) {
			return '@${(value : Date).getTime()}';
		}
		if (Reflect.isEnumValue(value)) {
			final params:Array<Dynamic> = Type.enumParameters(value);
			final name = Type.enumConstructor(value);
			return params.length == 0 ? name : name + "(" + params.map(p -> Write(p, depth + 1)).join(", ") + ")";
		}
		final cls = Type.getClass(value);
		if (cls == null) {
			final names = Reflect.fields(value);
			names.sort((a, b) -> a < b ? -1 : 1);
			return "{" + [for (name in names) '$name: ${Write(Reflect.field(value, name), depth + 1)}'].join(", ") + "}";
		}
		final names = [for (name in Type.getInstanceFields(cls)) if (!Reflect.isFunction(Reflect.field(value, name)) && name != "Ordinal") name];
		names.sort((a, b) -> a < b ? -1 : 1);
		final fields = [for (name in names) '$name: ${Write(Reflect.field(value, name), depth + 1)}'];
		return Type.getClassName(cls).split(".").pop() + "{" + fields.join(", ") + "}";
	}
}
