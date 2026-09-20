package codequery;

/**
	An exact number — what a column of money or measure is declared as.

	Haxe has one floating type; C# has three, and the schema tells them apart by the property's
	type. This is `decimal`: a column declared as one is `DECIMAL(18, 2)` until given a precision.
**/
abstract Decimal(Float) from Float from Int to Float {
	public inline function new(value:Float) {
		this = value;
	}

	public inline function toFloat():Float {
		return this;
	}

	@:op(A + B) static function add(a:Decimal, b:Decimal):Decimal return (a : Float) + (b : Float);
	@:op(A - B) static function sub(a:Decimal, b:Decimal):Decimal return (a : Float) - (b : Float);
	@:op(A * B) static function mul(a:Decimal, b:Decimal):Decimal return (a : Float) * (b : Float);
	@:op(A / B) static function div(a:Decimal, b:Decimal):Decimal return (a : Float) / (b : Float);
	@:op(A * B) static function mulInt(a:Decimal, b:Int):Decimal return (a : Float) * b;
	@:op(A / B) static function divInt(a:Decimal, b:Int):Decimal return (a : Float) / b;
	@:op(A > B) static function gt(a:Decimal, b:Decimal):Bool return (a : Float) > (b : Float);
	@:op(A >= B) static function gte(a:Decimal, b:Decimal):Bool return (a : Float) >= (b : Float);
	@:op(A < B) static function lt(a:Decimal, b:Decimal):Bool return (a : Float) < (b : Float);
	@:op(A <= B) static function lte(a:Decimal, b:Decimal):Bool return (a : Float) <= (b : Float);
	@:op(A == B) static function eq(a:Decimal, b:Decimal):Bool return (a : Float) == (b : Float);
	@:op(A != B) static function ne(a:Decimal, b:Decimal):Bool return (a : Float) != (b : Float);
}
