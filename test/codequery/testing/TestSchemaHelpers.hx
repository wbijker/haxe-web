package codequery.testing;

#if macro
import haxe.macro.Expr;
#end

/**
	The C# test project's `TestSchemaHelpers`: hand-authored snapshot fixtures. `DefineTable(Book)`
	adds an empty, entity-bound table and answers with a typed builder over it — C#'s
	`DefineTable<Book>()`. `SchemaSnapshot.DefineTable` does the same here, and being the
	snapshot's own member is what a call reaches; this stands beside it for the C# `using`.
**/
class TestSchemaHelpers {
	public static macro function DefineTable(snapshot:Expr, entity:Expr, ?name:Expr):Expr {
		return name == null ? macro $snapshot.DefineTable($entity) : macro $snapshot.DefineTable($entity, $name);
	}
}
