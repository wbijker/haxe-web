package codequery.migrations;

import codequery.sqldrivers.ISqlTranslator;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.TableConstraint;

/** A named list of schema changes, built fluently or from a diff, rendered by a driver. */
class SqlMigration {
	public final Name:String;
	public final Operations:Array<SchemaChangeExpression> = [];

	public function new(name:String) {
		this.Name = name;
	}

	public static function FromOperations(name:String, operations:Array<SchemaChangeExpression>):SqlMigration {
		final migration = new SqlMigration(name);
		for (op in operations) {
			migration.Operations.push(op);
		}
		return migration;
	}

	/** The changes that turn one table into another. */
	public static function FromDiff(name:String, from:Null<DatabaseTableDefinition>, to:DatabaseTableDefinition):SqlMigration {
		return FromOperations(name, to.Diff(from));
	}

	public function Add(operation:SchemaChangeExpression):SqlMigration {
		Operations.push(operation);
		return this;
	}

	public function CreateTable(name:String, columns:Array<ColumnDefinition>, ?constraints:Array<TableConstraint>, ?schema:String,
			ifNotExists:Bool = false):SqlMigration {
		return Add(new CreateTableExpression(name, columns, constraints, schema, ifNotExists));
	}

	public function CreateTableFrom(definition:DatabaseTableDefinition, ifNotExists:Bool = false):SqlMigration {
		return Add(definition.ToCreateTableExpression(ifNotExists));
	}

	public function DropTable(name:String, ?schema:String, ifExists:Bool = false, cascade:Bool = false):SqlMigration {
		return Add(new DropTableExpression(name, schema, ifExists, cascade));
	}

	public function RenameTable(oldName:String, newName:String, ?schema:String):SqlMigration {
		return Add(new RenameTableExpression(oldName, newName, schema));
	}

	public function AddColumn(table:String, column:ColumnDefinition, ?schema:String):SqlMigration {
		return Add(new AddColumnExpression(table, column, schema));
	}

	public function DropColumn(table:String, column:String, ?schema:String):SqlMigration {
		return Add(new DropColumnExpression(table, column, schema));
	}

	public function AlterColumn(table:String, column:String, newDefinition:ColumnDefinition, ?oldDefinition:ColumnDefinition,
			?schema:String):SqlMigration {
		return Add(new AlterColumnExpression(table, column, newDefinition, oldDefinition, schema));
	}

	public function RenameColumn(table:String, oldName:String, newName:String, ?schema:String):SqlMigration {
		return Add(new RenameColumnExpression(table, oldName, newName, schema));
	}

	public function AddConstraint(table:String, constraint:TableConstraint, ?schema:String):SqlMigration {
		return Add(new AddConstraintExpression(table, constraint, schema));
	}

	public function DropConstraint(table:String, constraint:String, ?schema:String):SqlMigration {
		return Add(new DropConstraintExpression(table, constraint, schema));
	}

	public function CreateIndex(table:String, index:String, columns:Array<IndexColumnDefinition>, isUnique:Bool = false,
			?schema:String):SqlMigration {
		return Add(new CreateIndexExpression(table, index, columns, isUnique, false, null, schema));
	}

	public function DropIndex(table:String, index:String, ?schema:String, ifExists:Bool = false):SqlMigration {
		return Add(new DropIndexExpression(table, index, schema, ifExists));
	}

	/** Each operation as SQL, one statement each. */
	public function ToSql(translator:ISqlTranslator):Array<String> {
		return [for (op in Operations) translator.ToSql(op)];
	}

	/** The whole migration as one script, a statement a line and a semicolon after each. */
	public function ToSqlScript(translator:ISqlTranslator):String {
		return [for (sql in ToSql(translator)) sql + ";"].join("\n");
	}
}
