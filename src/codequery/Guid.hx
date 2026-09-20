package codequery;

/**
	A GUID, held as its text.

	Haxe has no `System.Guid`; a column that is one is declared as this, so the schema knows to make
	it a `UUID` and a key of this type is the application's to generate rather than the database's.
**/
abstract Guid(String) from String to String {
	public static final Empty:Guid = "00000000-0000-0000-0000-000000000000";

	public inline function new(text:String) {
		this = text;
	}

	/** A fresh, random GUID. */
	public static function newGuid():Guid {
		final hex = (n:Int) -> StringTools.hex(Std.random(0x10000), 4).toLowerCase();
		return '${hex(0)}${hex(0)}-${hex(0)}-4${hex(0).substr(1)}-${hex(0)}-${hex(0)}${hex(0)}${hex(0)}';
	}

	public inline function toString():String {
		return this;
	}

	@:op(A == B) static function eq(a:Guid, b:Guid):Bool {
		return (a : String) == (b : String);
	}

	@:op(A != B) static function ne(a:Guid, b:Guid):Bool {
		return (a : String) != (b : String);
	}
}
