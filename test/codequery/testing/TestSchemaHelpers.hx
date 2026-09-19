package codequery.testing;

#if macro
import codequery.migrations.SchemaMembers;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	The C# test project's `TestSchemaHelpers`: hand-authored snapshot fixtures. `DefineTable(Book)`
	adds an empty, entity-bound table and answers with a typed builder over it — C#'s
	`DefineTable<Book>()` — reached with `using codequery.testing.TestSchemaHelpers;`.
**/
class TestSchemaHelpers {
	public static macro function DefineTable(snapshot:Expr, entity:Expr, ?name:Expr, ?schema:Expr):Expr {
		final row = SchemaMembers.ClassTypeOf(entity);
		final path = SchemaMembers.PathOf(row);
		final tableName = name == null || name.expr.match(EConst(CIdent("null"))) ? macro $v{row.name} : name;
		final held = schema == null ? macro null : schema;
		final type = haxe.macro.TypeTools.toComplexType(SchemaMembers.TypeOf(entity));
		return macro {
			final __snapshot = $snapshot;
			final __table = __snapshot.Table($tableName, $held);
			__snapshot.EntityTables.set($v{path}, __table);
			(__snapshot.EntityNamed($v{path}, $v{row.name}) : codequery.migrations.EntityTableBuilder<$type>);
		};
	}
}
