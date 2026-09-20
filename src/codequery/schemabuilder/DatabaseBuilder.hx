package codequery.schemabuilder;

import codequery.migrations.DatabaseTableDefinition;
import codequery.sqlexpressions.SchemaChangeExpression;
#if macro
import codequery.migrations.SchemaMembers;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Several tables built against their entity types, and the schema expressions that create them.
	`AddTable(User, "Users")` is C#'s `AddTable<User>("Users")`.
**/
class DatabaseBuilder {
	final tables:Array<DatabaseTableDefinition> = [];
	final tableNames = new Map<String, String>();

	public function new() {}

	/** A builder for an entity's table, named for the entity unless told otherwise. */
	public macro function AddTable(self:Expr, entity:Expr, ?tableName:Expr):Expr {
		final row = SchemaMembers.ClassTypeOf(entity);
		final path = SchemaMembers.PathOf(row);
		final type = haxe.macro.TypeTools.toComplexType(SchemaMembers.TypeOf(entity));
		final name = tableName == null || tableName.expr.match(EConst(CIdent("null"))) ? macro $v{row.name} : tableName;
		return macro($self.AddTableNamed($v{path}, $name) : codequery.schemabuilder.DatabaseTableBuilder<$type>);
	}

	/** What `AddTable` expands to. */
	public function AddTableNamed(entity:String, tableName:String):Dynamic {
		tableNames.set(entity, tableName);
		return new DatabaseTableBuilder<Dynamic>(tableName, this);
	}

	/** The table an entity was added as, or the entity's own name. */
	public function TableNameOf(entity:String, fallback:String):String {
		final known = tableNames.get(entity);
		return known == null ? fallback : known;
	}

	public function RegisterTable(table:DatabaseTableDefinition):Void {
		tables.push(table);
	}

	public var Tables(get, never):Array<DatabaseTableDefinition>;

	function get_Tables():Array<DatabaseTableDefinition> {
		return tables;
	}

	public function ToCreateTableExpressions(ifNotExists:Bool = false):Array<CreateTableExpression> {
		return tables.map(t -> t.ToCreateTableExpression(ifNotExists));
	}

	public function ToSchemaExpressions(ifNotExists:Bool = false):Array<SchemaChangeExpression> {
		final expressions:Array<SchemaChangeExpression> = [];
		for (table in tables) {
			expressions.push(table.ToCreateTableExpression(ifNotExists));
			for (index in table.Indexes) {
				expressions.push(index.ToCreateIndexExpression(table.TableName, table.Schema, ifNotExists));
			}
		}
		return expressions;
	}
}
