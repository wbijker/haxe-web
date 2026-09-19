package codequery.sqlexpressions;

/** Something a statement can select from. Everything a query names is reached through its alias. */
interface ISqlSource {
	public var Alias(default, null):String;
}
