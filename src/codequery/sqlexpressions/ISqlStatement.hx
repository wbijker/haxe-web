package codequery.sqlexpressions;

/**
	A statement a driver can render — a SELECT, an UPDATE, a DELETE or an INSERT.

	C# tells them apart by overloading `ToSql`. Haxe has no overloading, so they share a marker and
	the driver asks which one it has.
**/
interface ISqlStatement {}
