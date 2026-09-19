package codequery.sqldrivers;

import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.SqlType;
import codequery.sqlexpressions.TableConstraint;
import codequery.sqlexpressions.TableCreateExpression;

/**
	Schema changes as the DDL that makes them, in the generic dialect.

	The C# base translator's DDL, less what a dialect overrides: identifiers bare, the standard's
	`GENERATED … AS IDENTITY` for a key the database numbers. What a column's DEFAULT or CHECK says
	is an expression, rendered without quoting since a column in a table's own definition names no
	source and takes no alias.
**/
class DdlRenderer {
	final expressions = new AnsiSqlRenderer(false);

	public function new() {}

	public function Render(change:SchemaChangeExpression):String {
		final create = Std.downcast(change, CreateTableExpression);
		if (create != null) {
			final parts = create.Columns.map(Column).concat(create.Constraints.map(Constraint));
			return 'CREATE TABLE ${IfNotExists(create.IfNotExists)}${Table(create.TableName, create.Schema)} (${parts.join(", ")})';
		}

		final drop = Std.downcast(change, DropTableExpression);
		if (drop != null) {
			return 'DROP TABLE ${drop.IfExists ? "IF EXISTS " : ""}${Table(drop.TableName, drop.Schema)}${CascadeClause(drop.Cascade)}';
		}

		final rename = Std.downcast(change, RenameTableExpression);
		if (rename != null) {
			return 'ALTER TABLE ${Table(rename.OldTableName, rename.Schema)} RENAME TO ${rename.NewTableName}';
		}

		final add = Std.downcast(change, AddColumnExpression);
		if (add != null) {
			final table = Table(add.TableName, add.Schema);
			if (add.Backfill == null) {
				return 'ALTER TABLE $table ADD COLUMN ${Column(add.Column)}';
			}
			// Written in for the rows already there, and taken off again: the schema declares no default.
			return 'ALTER TABLE $table ADD COLUMN ${Column(add.Column)} DEFAULT ${Default(add.Backfill)};\n'
				+ 'ALTER TABLE $table ALTER COLUMN ${add.Column.Name} DROP DEFAULT';
		}

		final dropColumn = Std.downcast(change, DropColumnExpression);
		if (dropColumn != null) {
			return 'ALTER TABLE ${Table(dropColumn.TableName, dropColumn.Schema)} DROP COLUMN ${dropColumn.ColumnName}${CascadeClause(dropColumn.Cascade)}';
		}

		final alter = Std.downcast(change, AlterColumnExpression);
		if (alter != null) {
			return AlterColumn(alter);
		}

		final renameColumn = Std.downcast(change, RenameColumnExpression);
		if (renameColumn != null) {
			return 'ALTER TABLE ${Table(renameColumn.TableName, renameColumn.Schema)} RENAME COLUMN ${renameColumn.OldColumnName} TO ${renameColumn.NewColumnName}';
		}

		final addConstraint = Std.downcast(change, AddConstraintExpression);
		if (addConstraint != null) {
			return 'ALTER TABLE ${Table(addConstraint.TableName, addConstraint.Schema)} ADD ${Constraint(addConstraint.Constraint)}';
		}

		final dropConstraint = Std.downcast(change, DropConstraintExpression);
		if (dropConstraint != null) {
			return 'ALTER TABLE ${Table(dropConstraint.TableName, dropConstraint.Schema)} DROP CONSTRAINT ${dropConstraint.ConstraintName}${CascadeClause(dropConstraint.Cascade)}';
		}

		final createIndex = Std.downcast(change, CreateIndexExpression);
		if (createIndex != null) {
			return CreateIndex(createIndex);
		}

		final dropIndex = Std.downcast(change, DropIndexExpression);
		if (dropIndex != null) {
			return 'DROP INDEX ${dropIndex.IfExists ? "IF EXISTS " : ""}${dropIndex.IndexName}${CascadeClause(dropIndex.Cascade)}';
		}

		final renameIndex = Std.downcast(change, RenameIndexExpression);
		if (renameIndex != null) {
			return 'ALTER INDEX ${renameIndex.OldIndexName} RENAME TO ${renameIndex.NewIndexName}';
		}

		final sequence = Std.downcast(change, CreateSequenceExpression);
		if (sequence != null) {
			var sql = 'CREATE SEQUENCE ${IfNotExists(sequence.IfNotExists)}${Table(sequence.Name, sequence.Schema)}';
			sql += ' START WITH ${sequence.StartWith} INCREMENT BY ${sequence.IncrementBy}';
			sql += sequence.MinValue == null ? " NO MINVALUE" : ' MINVALUE ${sequence.MinValue}';
			sql += sequence.MaxValue == null ? " NO MAXVALUE" : ' MAXVALUE ${sequence.MaxValue}';
			return sql + (sequence.Cycle ? " CYCLE" : " NO CYCLE");
		}

		final dropSequence = Std.downcast(change, DropSequenceExpression);
		if (dropSequence != null) {
			return 'DROP SEQUENCE ${dropSequence.IfExists ? "IF EXISTS " : ""}${Table(dropSequence.Name, dropSequence.Schema)}';
		}

		throw 'Cannot render ${Type.getClassName(Type.getClass(change))}';
	}

	/** A CREATE TABLE on its own. */
	public function CreateTable(create:TableCreateExpression):String {
		final parts = create.Columns.map(Column).concat(create.Constraints.map(Constraint));
		return 'CREATE TABLE ${IfNotExists(create.IfNotExists)}${create.TableName} (${parts.join(", ")})';
	}

	static function IfNotExists(wanted:Bool):String {
		return wanted ? "IF NOT EXISTS " : "";
	}

	static function CascadeClause(wanted:Bool):String {
		return wanted ? " CASCADE" : "";
	}

	static function Table(name:String, schema:Null<String>):String {
		return schema == null || schema == "" ? name : '$schema.$name';
	}

	/** One column as the table's definition says it. */
	public function Column(column:ColumnDefinition):String {
		if (column.GeneratedExpression != null || column.GeneratedExpressionTree != null) {
			final expression = column.GeneratedExpressionTree != null
				? expressions.Render(column.GeneratedExpressionTree)
				: column.GeneratedExpression;
			final stored = column.GeneratedStored == false ? "VIRTUAL" : "STORED";
			return '${column.Name} ${TypeName(column)} GENERATED ALWAYS AS ($expression) $stored';
		}

		// No identity keyword: as in the C# base, that is each dialect's own spelling to add.
		final parts = [column.Name, TypeName(column)];
		if (column.Collation != null && column.Collation != "") {
			parts.push('COLLATE "${column.Collation}"');
		}
		if (!column.IsNullable) {
			parts.push("NOT NULL");
		}
		if (column.DefaultValue != null) {
			parts.push('DEFAULT ${Default(column.DefaultValue)}');
		} else if (column.ServerGeneratedGuid) {
			throw 'The generic dialect cannot server-generate a GUID key for ${column.Name}: no server-side UUID function; use a client-generated key';
		}
		return parts.join(" ");
	}

	function Default(expression:ISqlExpression):String {
		return expressions.Render(expression);
	}

	/** The type as the DDL spells it, with the width or precision the column carries. */
	public static function TypeName(column:ColumnDefinition):String {
		return switch column.Type {
			case SqlText: column.MaxLength == null ? "TEXT" : 'VARCHAR(${column.MaxLength})';
			case SqlChar: column.MaxLength == null ? "CHAR" : 'CHAR(${column.MaxLength})';
			case SqlBinary: column.MaxLength == null ? "BLOB" : 'VARBINARY(${column.MaxLength})';
			case SqlDecimal(_, _):
				column.Precision == null
					? "DECIMAL"
					: (column.Scale == null ? 'DECIMAL(${column.Precision})' : 'DECIMAL(${column.Precision}, ${column.Scale})');
			case other: AnsiSqlRenderer.TypeName(other);
		}
	}

	public function Constraint(constraint:TableConstraint):String {
		final name = constraint.Name != null ? 'CONSTRAINT ${constraint.Name} ' : "";

		final pk = Std.downcast(constraint, PrimaryKeyConstraint);
		final unique = Std.downcast(constraint, UniqueConstraint);
		final fk = Std.downcast(constraint, ForeignKeyConstraint);
		final check = Std.downcast(constraint, CheckConstraint);

		final body = if (pk != null) {
			'${name}PRIMARY KEY (${pk.Columns.join(", ")})';
		} else if (unique != null) {
			'${name}UNIQUE (${unique.Columns.join(", ")})';
		} else if (fk != null) {
			var sql = '${name}FOREIGN KEY (${fk.Columns.join(", ")}) REFERENCES ${fk.ReferencedTable} (${fk.ReferencedColumns.join(", ")})';
			if (fk.OnDelete != NoAction) {
				sql += ' ON DELETE ${Action(fk.OnDelete)}';
			}
			if (fk.OnUpdate != NoAction) {
				sql += ' ON UPDATE ${Action(fk.OnUpdate)}';
			}
			sql;
		} else if (check != null) {
			'${name}CHECK (${expressions.Render(check.Condition)})';
		} else {
			throw 'Constraint type ${Type.getClassName(Type.getClass(constraint))} is not supported';
		}

		final deferrable = !constraint.Deferrable ? "" : (constraint.InitiallyDeferred ? " DEFERRABLE INITIALLY DEFERRED" : " DEFERRABLE");
		return body + deferrable;
	}

	static function Action(action:ForeignKeyAction):String {
		return switch action {
			case NoAction: "NO ACTION";
			case Cascade: "CASCADE";
			case SetNull: "SET NULL";
			case SetDefault: "SET DEFAULT";
			case Restrict: "RESTRICT";
		}
	}

	function AlterColumn(alter:AlterColumnExpression):String {
		final table = Table(alter.TableName, alter.Schema);
		final now = alter.NewDefinition;
		final was = alter.OldDefinition;

		// A column that stays generated changes only its expression.
		if (now.GeneratedExpression != null || now.GeneratedExpressionTree != null) {
			final expression = now.GeneratedExpressionTree != null ? expressions.Render(now.GeneratedExpressionTree) : now.GeneratedExpression;
			return 'ALTER TABLE $table ALTER COLUMN ${alter.ColumnName} SET EXPRESSION AS ($expression)';
		}

		final actions = ['ALTER COLUMN ${alter.ColumnName} TYPE ${TypeName(now)}'];
		if (was == null || was.IsNullable != now.IsNullable) {
			actions.push('ALTER COLUMN ${alter.ColumnName} ${now.IsNullable ? "DROP NOT NULL" : "SET NOT NULL"}');
		}
		if (now.DefaultValue != null) {
			actions.push('ALTER COLUMN ${alter.ColumnName} SET DEFAULT ${Default(now.DefaultValue)}');
		} else if (was != null && was.DefaultValue != null) {
			actions.push('ALTER COLUMN ${alter.ColumnName} DROP DEFAULT');
		}
		return 'ALTER TABLE $table ${actions.join(", ")}';
	}

	function CreateIndex(index:CreateIndexExpression):String {
		final unique = index.IsUnique ? "UNIQUE " : "";
		final method = index.Method == null || index.Method == "" ? "" : 'USING ${index.Method} ';
		final columns = index.Columns.map(c -> c.Descending ? '${c.ColumnName} DESC' : c.ColumnName).join(", ");
		var sql = 'CREATE ${unique}INDEX ${IfNotExists(index.IfNotExists)}${index.IndexName} ON ${Table(index.TableName, index.Schema)} $method($columns)';
		if (index.IncludeColumns.length > 0) {
			sql += ' INCLUDE (${index.IncludeColumns.join(", ")})';
		}
		if (index.FilterExpression != null && index.FilterExpression != "") {
			sql += ' WHERE ${index.FilterExpression}';
		}
		return sql;
	}
}
