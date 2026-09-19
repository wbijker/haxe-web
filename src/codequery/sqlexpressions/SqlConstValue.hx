package codequery.sqlexpressions;

/**
	A literal value. The C# original is a class per kind (`SqlConstInt`, `SqlConstString`, …);
	an enum says the same thing in Haxe and lets the driver match on it exhaustively.
**/
enum SqlConstValue {
	SqlConstBool(value:Bool);
	SqlConstInt(value:Int);
	SqlConstFloat(value:Float);
	SqlConstString(value:String);
	SqlConstDate(value:Date);
	SqlConstNull;
}
