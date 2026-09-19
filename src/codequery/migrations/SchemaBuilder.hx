package codequery.migrations;

#if macro
import codequery.inspection.SchemaInspector;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/**
	Reads the schema off the entities, while compiling.

	C# reflects over the schema class at runtime to find what it declares. Here the same walk
	happens during compilation: each `DbTable<T>` member's entity is inspected by `SchemaInspector`,
	so a column of the schema and a column of a query cannot disagree about what a table has.
**/
class SchemaBuilder {
	/**
		The schema a class declares, from its `DbTable` members.

		A view is described but not built: it is a query given a name, and what creates one is the
		query, not a list of columns.
	**/
	public static macro function Of(schema:Expr):Expr {
		final declared = SchemaMembers.ClassTypeOf(schema);
		final tables:Array<Expr> = [];
		for (table in SchemaMembers.TablesOf(declared)) {
			tables.push(SchemaInspector.Inspect(table.row, schema.pos));
		}
		final list = {expr: EArrayDecl(tables), pos: schema.pos};
		return macro codequery.migrations.DatabaseSchema.FromTables($list, $v{declared.name});
	}
}
