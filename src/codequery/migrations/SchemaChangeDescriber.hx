package codequery.migrations;

import codequery.migrations.DatabaseColumnType;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.TableConstraint;

/**
	A migration's operations as short, readable lines — the comments at the top of each generated
	script, so a reviewer sees what it does to the schema without reading the DDL. Seed rows are
	counted per table so a large data set does not produce hundreds of lines.
**/
class SchemaChangeDescriber {
	public static function Summarize(operations:Array<SchemaChangeExpression>):Array<String> {
		final lines:Array<String> = [];
		final seeds = new Map<String, Int>();
		final seedKeys:Array<String> = [];

		for (op in operations) {
			final seed = Std.downcast(op, SeedDataExpression);
			if (seed != null) {
				final key = Qualify(seed.Schema, seed.TableName) + "\t" + Std.string(seed.Operation).toLowerCase();
				if (!seeds.exists(key)) {
					seedKeys.push(key);
				}
				seeds.set(key, (seeds.exists(key) ? seeds.get(key) : 0) + 1);
			} else {
				lines.push(Describe(op));
			}
		}

		seedKeys.sort((a, b) -> SchemaCanonicalizer.Compare(a, b));
		for (key in seedKeys) {
			final parts = key.split("\t");
			lines.push('Seed: ${seeds.get(key)} ${parts[1]} row(s) in "${parts[0]}"');
		}
		return lines;
	}

	static function Describe(op:SchemaChangeExpression):String {
		final create = Std.downcast(op, CreateTableExpression);
		if (create != null) return 'Create table "${Qualify(create.Schema, create.TableName)}" (${create.Columns.length} column${Plural(create.Columns.length)})';
		final drop = Std.downcast(op, DropTableExpression);
		if (drop != null) return 'Drop table "${Qualify(drop.Schema, drop.TableName)}"';
		final renameTable = Std.downcast(op, RenameTableExpression);
		if (renameTable != null) return 'Rename table "${Qualify(renameTable.Schema, renameTable.OldTableName)}" -> "${renameTable.NewTableName}"';
		final add = Std.downcast(op, AddColumnExpression);
		if (add != null) return 'Add column "${add.TableName}"."${add.Column.Name}" (${TypeName(add.Column.Type)})';
		final dropColumn = Std.downcast(op, DropColumnExpression);
		if (dropColumn != null) return 'Drop column "${dropColumn.TableName}"."${dropColumn.ColumnName}"';
		final alter = Std.downcast(op, AlterColumnExpression);
		if (alter != null) return 'Alter column "${alter.TableName}"."${alter.ColumnName}"${AlterDetail(alter)}';
		final renameColumn = Std.downcast(op, RenameColumnExpression);
		if (renameColumn != null) return 'Rename column "${renameColumn.TableName}"."${renameColumn.OldColumnName}" -> "${renameColumn.NewColumnName}"';
		final addConstraint = Std.downcast(op, AddConstraintExpression);
		if (addConstraint != null) return 'Add ${ConstraintKind(addConstraint.Constraint)} "${addConstraint.Constraint.Name}" on "${addConstraint.TableName}"';
		final dropConstraint = Std.downcast(op, DropConstraintExpression);
		if (dropConstraint != null) return 'Drop constraint "${dropConstraint.ConstraintName}" on "${dropConstraint.TableName}"';
		final createIndex = Std.downcast(op, CreateIndexExpression);
		if (createIndex != null) return 'Create ${createIndex.IsUnique ? "unique index" : "index"} "${createIndex.IndexName}" on "${createIndex.TableName}" (${[for (c in createIndex.Columns) c.ColumnName].join(", ")})';
		final dropIndex = Std.downcast(op, DropIndexExpression);
		if (dropIndex != null) return 'Drop index "${dropIndex.IndexName}" on "${dropIndex.TableName}"';
		final renameIndex = Std.downcast(op, RenameIndexExpression);
		if (renameIndex != null) return 'Rename index "${renameIndex.OldIndexName}" -> "${renameIndex.NewIndexName}" on "${renameIndex.TableName}"';
		final dropType = Std.downcast(op, DropTypeExpression);
		if (dropType != null) return 'Drop ${dropType.IsDomain ? "domain" : "type"} "${Qualify(dropType.Schema, dropType.TypeName)}"';
		final createRoutine = Std.downcast(op, CreateRoutineExpression);
		if (createRoutine != null) return 'Create or replace ${Std.string(createRoutine.Kind).toLowerCase()} "${Qualify(createRoutine.Schema, createRoutine.Name)}"';
		final dropRoutine = Std.downcast(op, DropRoutineExpression);
		if (dropRoutine != null) return 'Drop ${Std.string(dropRoutine.Kind).toLowerCase()} "${Qualify(dropRoutine.Schema, dropRoutine.Name)}"';
		final statement = Std.downcast(op, StatementExpression);
		if (statement != null) return '${statement.IsUndo ? "Remove" : "Apply"} "${statement.Name}"';
		return Type.getClassName(Type.getClass(op)).split(".").pop();
	}

	static function TypeName(type:codequery.sqlexpressions.SqlType):String {
		return Std.string(DatabaseColumnTypes.OfSqlType(type).type);
	}

	static function AlterDetail(e:AlterColumnExpression):String {
		if (e.OldDefinition == null) {
			return "";
		}
		if (Std.string(e.OldDefinition.Type) != Std.string(e.NewDefinition.Type)) {
			return ' (type ${TypeName(e.OldDefinition.Type)} -> ${TypeName(e.NewDefinition.Type)})';
		}
		if (e.OldDefinition.IsNullable != e.NewDefinition.IsNullable) {
			return e.NewDefinition.IsNullable ? " (now nullable)" : " (now NOT NULL)";
		}
		return "";
	}

	static function ConstraintKind(c:TableConstraint):String {
		if (Std.isOfType(c, PrimaryKeyConstraint)) return "primary key";
		if (Std.isOfType(c, ForeignKeyConstraint)) return "foreign key";
		if (Std.isOfType(c, UniqueConstraint)) return "unique constraint";
		if (Std.isOfType(c, CheckConstraint)) return "check constraint";
		return "constraint";
	}

	static function Qualify(schema:Null<String>, name:String):String {
		return schema == null || schema == "" ? name : '$schema.$name';
	}

	static function Plural(count:Int):String {
		return count == 1 ? "" : "s";
	}
}
