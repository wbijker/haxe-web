package codequery.migrations;

/**
	A statement's tree as text, and back — the C# `SqlTreeSerializer`, which is what a snapshot
	records a view's definition as: the native structure, so that how a driver would lay the SQL
	out never counts as a change.

	Written by looking rather than by a serializer per class: every object is its class name and
	its fields, an enum value its constructor and its arguments. An object met twice is written once
	and referred to after — a column and the FROM clause name the same source, and a driver that
	aliases sources by identity needs them to still be one object when read back.
**/
class SqlTreeSerializer {
	/** The tree as JSON. */
	public static function Serialize(value:Dynamic):String {
		return haxe.Json.stringify(new Writer().Write(value));
	}

	/** The tree back from `Serialize`, an instance of `cls` — or whatever class the text names. */
	public static function Deserialize(json:String, ?cls:Class<Dynamic>):Dynamic {
		return new Reader().Read(haxe.Json.parse(json));
	}

	/**
		The structure alone, with references written by number rather than by identity, so two
		trees of the same shape are the same text however they were built or would be rendered.
	**/
	public static function Canonical(value:Dynamic):String {
		return Serialize(value);
	}
}

private class Writer {
	final seen = new haxe.ds.ObjectMap<{}, Int>();
	var next = 0;

	public function new() {}

	public function Write(value:Dynamic):Dynamic {
		if (value == null || Std.isOfType(value, Bool) || Std.isOfType(value, Int) || Std.isOfType(value, Float) || Std.isOfType(value, String)) {
			return value;
		}
		if (Std.isOfType(value, Date)) {
			return {"$date": (value : Date).getTime()};
		}
		if (Std.isOfType(value, Array)) {
			final items:Array<Dynamic> = value;
			return [for (item in items) Write(item)];
		}
		if (Reflect.isEnumValue(value)) {
			final e:EnumValue = value;
			return {
				"$enum": Type.getEnumName(Type.getEnum(e)),
				"$ctor": Type.enumConstructor(e),
				"$args": [for (arg in Type.enumParameters(e)) Write(arg)]
			};
		}
		if (Std.isOfType(value, haxe.ds.StringMap)) {
			final map:Map<String, Dynamic> = value;
			final held:Dynamic = {};
			for (key in map.keys()) {
				Reflect.setField(held, key, Write(map.get(key)));
			}
			return {"$map": held};
		}

		final cls = Type.getClass(value);
		if (cls == null) {
			// An anonymous structure.
			final held:Dynamic = {};
			for (name in Reflect.fields(value)) {
				Reflect.setField(held, name, Write(Reflect.field(value, name)));
			}
			return held;
		}

		if (seen.exists(value)) {
			return {"$ref": seen.get(value)};
		}
		final id = next++;
		seen.set(value, id);

		final held:Dynamic = {"$class": Type.getClassName(cls), "$id": id};
		for (name in Reflect.fields(value)) {
			final field = Reflect.field(value, name);
			if (Reflect.isFunction(field)) {
				continue;
			}
			Reflect.setField(held, name, Write(field));
		}
		return held;
	}
}

private class Reader {
	final made = new Map<Int, Dynamic>();

	public function new() {}

	public function Read(value:Dynamic):Dynamic {
		if (value == null || Std.isOfType(value, Bool) || Std.isOfType(value, Int) || Std.isOfType(value, Float) || Std.isOfType(value, String)) {
			return value;
		}
		if (Std.isOfType(value, Array)) {
			final items:Array<Dynamic> = value;
			return [for (item in items) Read(item)];
		}
		if (Reflect.hasField(value, "$date")) {
			return Date.fromTime(Reflect.field(value, "$date"));
		}
		if (Reflect.hasField(value, "$ref")) {
			return made.get(Reflect.field(value, "$ref"));
		}
		if (Reflect.hasField(value, "$enum")) {
			final e = Type.resolveEnum(Reflect.field(value, "$enum"));
			final args:Array<Dynamic> = Reflect.field(value, "$args");
			return Type.createEnum(e, Reflect.field(value, "$ctor"), [for (arg in args) Read(arg)]);
		}
		if (Reflect.hasField(value, "$map")) {
			final map = new Map<String, Dynamic>();
			final held = Reflect.field(value, "$map");
			for (name in Reflect.fields(held)) {
				map.set(name, Read(Reflect.field(held, name)));
			}
			return map;
		}
		if (Reflect.hasField(value, "$class")) {
			final cls = Type.resolveClass(Reflect.field(value, "$class"));
			if (cls == null) {
				throw 'Cannot read a ${Reflect.field(value, "$class")}: no such class';
			}
			final instance = Type.createEmptyInstance(cls);
			made.set(Reflect.field(value, "$id"), instance);
			for (name in Reflect.fields(value)) {
				if (name.charAt(0) == "$") {
					continue;
				}
				Reflect.setField(instance, name, Read(Reflect.field(value, name)));
			}
			return instance;
		}
		final held:Dynamic = {};
		for (name in Reflect.fields(value)) {
			Reflect.setField(held, name, Read(Reflect.field(value, name)));
		}
		return held;
	}
}
