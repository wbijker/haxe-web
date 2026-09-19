package codequery;

import codequery.sqlexpressions.ColumnsBuilder;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Entry point for a strongly-typed `MERGE` statement:

	```haxe
	Merge.Into(Account)
		.Using(staging, (t, s) -> t.id == s.id)
		.WhenMatchedUpdate((t, s) -> {balance: s.balance})
		.WhenNotMatchedInsert((t, s) -> {id: s.id, balance: s.balance})
		.Build();
	```

	The target is `t` and the source is `s` in every lambda. C#'s `Merge.Into<TTarget>()`.
**/
class Merge {
	/** Starts a MERGE into the named entity's table. */
	public static macro function Into(target:Expr):Expr {
		final name = switch target.expr {
			case EConst(CIdent(name)): name;
			case EField(_, _, _): new haxe.macro.Printer().printExpr(target);
			case _: Context.error("Name the entity type, e.g. Merge.Into(Account)", target.pos);
		}
		final type = Context.getType(name);
		final path = haxe.macro.TypeTools.toComplexType(type);
		final tableName = ColumnsBuilder.TableNameOfType(type);
		return macro(cast new codequery.queries.MergeBuilderImpl(new codequery.QualifiedTableName($v{tableName}))
			: codequery.queries.IMergeInto<$path>);
	}
}
