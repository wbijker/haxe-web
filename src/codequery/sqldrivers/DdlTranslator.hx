package codequery.sqldrivers;

import codequery.migrations.SchemaChange;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.SqlType;
import codequery.sqlexpressions.TableConstraint;
import codequery.sqlexpressions.TablePartition;

/**
	Renders schema changes as DDL — the part of the C# `SqlTranslatorBase` that deals in tables
	rather than rows, kept beside the translator rather than in it.

	One generic, PostgreSQL-ish dialect: identifiers are written bare, as the translator writes
	them everywhere else. What is rendered is the shape of the change; a dialect that spells a
	clause differently is not this port's concern.
**/
class DdlTranslator {
	final translator:SqlTranslator;
	final pretty:Bool;

	public function new(translator:SqlTranslator, pretty:Bool = false) {
		this.translator = translator;
		this.pretty = pretty;
	}

	/** The old enum form of a change, as the expression it stands for. */
	public static function Expression(change:SchemaChange):SchemaChangeExpression {
		return switch change {
			case CreateTable(table): table.ToCreateTableExpression();
			case DropTable(table): new DropTableExpression(table.Name, table.Schema);
			case AddColumn(table, column): new AddColumnExpression(table, column.ToColumnDefinition());
			case DropColumn(table, column): new DropColumnExpression(table, column.Name);
			case AlterColumn(table, from, to):
				new AlterColumnExpression(table, to.Name, to.ToColumnDefinition(), from.ToColumnDefinition());
		}
	}

	public function Render(e:SchemaChangeExpression):String {
		final create = Std.downcast(e, CreateTableExpression);
		if (create != null) return CreateTable(create);
		final drop = Std.downcast(e, DropTableExpression);
		if (drop != null) return 'DROP TABLE ${drop.IfExists ? "IF EXISTS " : ""}${Table(drop.TableName, drop.Schema)}${CascadeClause(drop.Cascade)}';
		final renameTable = Std.downcast(e, RenameTableExpression);
		if (renameTable != null) return 'ALTER TABLE ${Table(renameTable.OldTableName, renameTable.Schema)} RENAME TO ${renameTable.NewTableName}';
		final add = Std.downcast(e, AddColumnExpression);
		if (add != null) return AddColumn(add);
		final dropColumn = Std.downcast(e, DropColumnExpression);
		if (dropColumn != null) return 'ALTER TABLE ${Table(dropColumn.TableName, dropColumn.Schema)} DROP COLUMN ${dropColumn.ColumnName}${CascadeClause(dropColumn.Cascade)}';
		final alter = Std.downcast(e, AlterColumnExpression);
		if (alter != null) return AlterColumn(alter);
		final renameColumn = Std.downcast(e, RenameColumnExpression);
		if (renameColumn != null) return 'ALTER TABLE ${Table(renameColumn.TableName, renameColumn.Schema)} RENAME COLUMN ${renameColumn.OldColumnName} TO ${renameColumn.NewColumnName}';
		final addConstraint = Std.downcast(e, AddConstraintExpression);
		if (addConstraint != null) return 'ALTER TABLE ${Table(addConstraint.TableName, addConstraint.Schema)} ADD ${Constraint(addConstraint.Constraint)}';
		final dropConstraint = Std.downcast(e, DropConstraintExpression);
		if (dropConstraint != null) return 'ALTER TABLE ${Table(dropConstraint.TableName, dropConstraint.Schema)} DROP CONSTRAINT ${dropConstraint.ConstraintName}${CascadeClause(dropConstraint.Cascade)}';
		final createIndex = Std.downcast(e, CreateIndexExpression);
		if (createIndex != null) return CreateIndex(createIndex);
		final dropIndex = Std.downcast(e, DropIndexExpression);
		if (dropIndex != null) return 'DROP INDEX ${dropIndex.IfExists ? "IF EXISTS " : ""}${dropIndex.IndexName}${CascadeClause(dropIndex.Cascade)}';
		final renameIndex = Std.downcast(e, RenameIndexExpression);
		if (renameIndex != null) return 'ALTER INDEX ${renameIndex.OldIndexName} RENAME TO ${renameIndex.NewIndexName}';
		final dropType = Std.downcast(e, DropTypeExpression);
		if (dropType != null) return 'DROP ${dropType.IsDomain ? "DOMAIN" : "TYPE"} ${dropType.IfExists ? "IF EXISTS " : ""}${Table(dropType.TypeName, dropType.Schema)}${CascadeClause(dropType.Cascade)}';
		final dropRoutine = Std.downcast(e, DropRoutineExpression);
		if (dropRoutine != null) return DropRoutine(dropRoutine);
		final createRoutine = Std.downcast(e, CreateRoutineExpression);
		if (createRoutine != null) return createRoutine.Body == null ? "" : createRoutine.Body;
		final seed = Std.downcast(e, SeedDataExpression);
		if (seed != null) return Seed(seed);
		final statement = Std.downcast(e, StatementExpression);
		if (statement != null) return statement.Sql;
		throw 'Schema change ${Type.getClassName(Type.getClass(e))} is not supported';
	}

	// ---- tables ------------------------------------------------------------------------------------

	function CreateTable(e:CreateTableExpression):String {
		final parts = [for (c in e.Columns) {sql: Column(c), note: c.ReferencesNote}];
		for (c in e.Constraints) {
			parts.push({sql: Constraint(c), note: null});
		}
		final ifNotExists = e.IfNotExists ? "IF NOT EXISTS " : "";
		final core = 'CREATE TABLE $ifNotExists${Table(e.TableName, e.Schema)} ${Wrap(Body(parts))}';
		return e.Partition == null ? core : Partitioned(core, e, e.Partition);
	}

	/**
		The columns and constraints between the brackets. A column whose foreign key was lifted out
		of the table carries a note saying what it points at — after the comma, since a line comment
		takes the rest of the line with it, and only when there is a rest of the line to take.
	**/
	function Body(parts:Array<{sql:String, note:Null<String>}>):String {
		final lines = [];
		for (index in 0...parts.length) {
			var text = parts[index].sql;
			if (index < parts.length - 1) {
				text += pretty ? "," : ", ";
			}
			if (pretty && parts[index].note != null) {
				text += '   -- → ${parts[index].note}';
			}
			lines.push(text);
		}
		return pretty ? lines.join("\n") : lines.join("");
	}

	function Wrap(body:String):String {
		if (!pretty) {
			return '($body)';
		}
		return "(\n    " + StringTools.replace(body, "\n", "\n    ") + "\n)";
	}

	function Partitioned(core:String, e:CreateTableExpression, partition:TablePartition):String {
		final strategy = switch partition.Strategy {
			case Range: "RANGE";
			case List: "LIST";
			case Hash: "HASH";
		}
		final statements:Array<String> = ['$core PARTITION BY $strategy (${partition.KeyExpression})'];
		final parent = Table(e.TableName, e.Schema);

		if (partition.Strategy == Hash && partition.Count != null) {
			for (slot in 0...partition.Count) {
				statements.push('CREATE TABLE ${e.TableName}_p$slot PARTITION OF $parent FOR VALUES WITH (MODULUS ${partition.Count}, REMAINDER $slot)');
			}
		}
		for (child in partition.Partitions) {
			final values = switch partition.Strategy {
				case Range: 'FROM (${child.From}) TO (${child.To})';
				case List: 'IN (${child.Values.join(", ")})';
				case Hash: 'WITH (MODULUS ${child.Modulus}, REMAINDER ${child.Remainder})';
			}
			statements.push('CREATE TABLE ${child.Name} PARTITION OF $parent FOR VALUES $values');
		}
		return statements.join(";\n");
	}

	// ---- columns -----------------------------------------------------------------------------------

	public function Column(column:ColumnDefinition):String {
		final parts = [column.Name, TypeName(column)];

		if (column.Collation != null && column.Collation != "") {
			parts.push('COLLATE ${column.Collation}');
		}
		if (column.IsAutoIncrement) {
			switch column.Identity {
				case Always: parts.push("GENERATED ALWAYS AS IDENTITY");
				// A SERIAL is a type rather than a clause; BY DEFAULT is what a key is, and goes unsaid.
				case Serial | ByDefault:
			}
		}
		if (!column.IsNullable) {
			parts.push("NOT NULL");
		}
		if (column.DefaultValue != null) {
			parts.push('DEFAULT ${Default(column.DefaultValue)}');
		}
		return parts.join(" ");
	}

	/** The column's type as the dialect names it, with the length or precision the column gives it. */
	public function TypeName(column:ColumnDefinition):String {
		if (column.IsAutoIncrement && column.Identity == Serial) {
			return switch column.Type {
				case SqlSmallInt: "SMALLSERIAL";
				case SqlBigInt: "BIGSERIAL";
				case SqlInt: "SERIAL";
				case t: throw 'Column "${column.Name}" is ${Std.string(t)}; SERIAL is an integer column only (SMALLSERIAL, SERIAL, BIGSERIAL).';
			}
		}
		return switch column.Type {
			case SqlText if (column.MaxLength != null): 'VARCHAR(${column.MaxLength})';
			case SqlVarChar(_) if (column.MaxLength != null): 'VARCHAR(${column.MaxLength})';
			case SqlVarChar(length) if (length <= 0): "TEXT";
			case SqlChar(_) if (column.MaxLength != null): 'CHAR(${column.MaxLength})';
			case SqlDecimal(_, _) | SqlFloat if (column.Precision != null):
				column.Scale == null ? 'DECIMAL(${column.Precision})' : 'DECIMAL(${column.Precision}, ${column.Scale})';
			case SqlDecimal(precision, _) if (precision <= 0): "DECIMAL";
			case t: translator.RenderType(t);
		}
	}

	function Default(value:ISqlExpression):String {
		return translator.RenderExpression(value);
	}

	function AddColumn(e:AddColumnExpression):String {
		final table = Table(e.TableName, e.Schema);
		final added = 'ALTER TABLE $table ADD COLUMN ${Column(e.Column)}';
		if (e.Backfill == null) {
			return added;
		}
		// Written in and taken off again: the rows need something, and a column the schema declares
		// no default for must not be left carrying one.
		return '$added DEFAULT ${Default(e.Backfill)};\nALTER TABLE $table ALTER COLUMN ${e.Column.Name} DROP DEFAULT';
	}

	function AlterColumn(e:AlterColumnExpression):String {
		final table = Table(e.TableName, e.Schema);
		final column = e.ColumnName;
		final now = e.NewDefinition;
		final was = e.OldDefinition;

		final actions = ['ALTER COLUMN $column TYPE ${TypeName(now)}'];

		if (was == null || was.IsNullable != now.IsNullable) {
			actions.push('ALTER COLUMN $column ${now.IsNullable ? "DROP NOT NULL" : "SET NOT NULL"}');
		}

		if (now.DefaultValue != null) {
			actions.push('ALTER COLUMN $column SET DEFAULT ${Default(now.DefaultValue)}');
		} else if (was != null && was.DefaultValue != null) {
			actions.push('ALTER COLUMN $column DROP DEFAULT');
		}

		final identity = IdentityChange(e);
		if (identity != null) {
			actions.push(identity);
		}

		return 'ALTER TABLE $table ${actions.join(", ")}';
	}

	/**
		A column whose identity form changed says so in one action of its own: SET GENERATED for a
		column that stays an identity, ADD GENERATED or DROP IDENTITY for one becoming or ceasing to
		be one. A SERIAL on either side is refused: it is a default drawing on a sequence, not an
		identity, and PostgreSQL cannot turn one into the other in a clause.
	**/
	function IdentityChange(e:AlterColumnExpression):Null<String> {
		final was = e.OldDefinition;
		final now = e.NewDefinition;
		final before = was == null ? null : (was.IsAutoIncrement ? was.Identity : null);
		final after = now.IsAutoIncrement ? now.Identity : null;
		if (Std.string(before) == Std.string(after)) {
			return null;
		}
		if (before == Serial || after == Serial) {
			throw 'Column "${e.ColumnName}" changes between SERIAL and an identity column, which PostgreSQL cannot do in one clause: a SERIAL is a DEFAULT drawing on a sequence, and an identity column owns its sequence.';
		}
		if (after == null) {
			return 'ALTER COLUMN ${e.ColumnName} DROP IDENTITY IF EXISTS';
		}
		final form = after == Always ? "ALWAYS" : "BY DEFAULT";
		return before == null
			? 'ALTER COLUMN ${e.ColumnName} ADD GENERATED $form AS IDENTITY'
			: 'ALTER COLUMN ${e.ColumnName} SET GENERATED $form';
	}

	// ---- constraints and indexes -------------------------------------------------------------------

	public function Constraint(constraint:TableConstraint):String {
		final name = constraint.Name != null ? 'CONSTRAINT ${constraint.Name} ' : "";

		final pk = Std.downcast(constraint, PrimaryKeyConstraint);

		final unique = Std.downcast(constraint, UniqueConstraint);
		final fk = Std.downcast(constraint, ForeignKeyConstraint);
		final check = Std.downcast(constraint, CheckConstraint);

		final body:String = if (pk != null) {
			'${name}PRIMARY KEY (${pk.Columns.join(", ")})';
		} else if (unique != null) {
			'${name}UNIQUE (${unique.Columns.join(", ")})';
		} else if (fk != null) {
			ForeignKey(fk, name);
		} else if (check != null) {
			'${name}CHECK (${translator.RenderExpression(check.Condition)})';
		} else {
			throw 'Constraint type ${Type.getClassName(Type.getClass(constraint))} is not supported';
		}

		return body + Deferrable(constraint);
	}

	function Deferrable(constraint:TableConstraint):String {
		if (!constraint.Deferrable) {
			return "";
		}
		return constraint.InitiallyDeferred ? " DEFERRABLE INITIALLY DEFERRED" : " DEFERRABLE";
	}

	function ForeignKey(fk:ForeignKeyConstraint, name:String):String {
		var sql = '${name}FOREIGN KEY (${fk.Columns.join(", ")}) REFERENCES ${fk.ReferencedTable} (${fk.ReferencedColumns.join(", ")})';
		if (fk.OnDelete != NoAction) {
			sql += ' ON DELETE ${Action(fk.OnDelete)}';
		}
		if (fk.OnUpdate != NoAction) {
			sql += ' ON UPDATE ${Action(fk.OnUpdate)}';
		}
		return sql;
	}

	function Action(action:ForeignKeyAction):String {
		return switch action {
			case NoAction: "NO ACTION";
			case Cascade: "CASCADE";
			case SetNull: "SET NULL";
			case SetDefault: "SET DEFAULT";
			case Restrict: "RESTRICT";
		}
	}

	function CreateIndex(e:CreateIndexExpression):String {
		final unique = e.IsUnique ? "UNIQUE " : "";
		final ifNotExists = e.IfNotExists ? "IF NOT EXISTS " : "";
		final method = e.Method == null || e.Method == "" ? "" : 'USING ${e.Method} ';
		final columns = [for (c in e.Columns) c.Descending ? '${c.ColumnName} DESC' : c.ColumnName].join(", ");

		// No clustered syntax on CREATE INDEX here: the flag is ignored, not emitted.
		var sql = 'CREATE ${unique}INDEX $ifNotExists${e.IndexName} ON ${Table(e.TableName, e.Schema)} $method($columns)';

		if (e.IncludeColumns.length > 0) {
			sql += ' INCLUDE (${e.IncludeColumns.join(", ")})';
		}
		if (e.FilterExpression != null && e.FilterExpression != "") {
			sql += ' WHERE ${e.FilterExpression}';
		}
		return sql;
	}

	function DropRoutine(e:DropRoutineExpression):String {
		final keyword = switch e.Kind {
			case Function: "FUNCTION";
			case View: "VIEW";
			case Procedure: "PROCEDURE";
			case Trigger: "TRIGGER";
		}
		if (e.Kind == Trigger) {
			return 'DROP TRIGGER IF EXISTS ${e.Name}' + (e.Table == null ? "" : ' ON ${e.Table}');
		}
		return 'DROP $keyword IF EXISTS ${Table(e.Name, e.Schema)}${CascadeClause(e.Cascade)}';
	}

	// ---- seed rows ---------------------------------------------------------------------------------

	function Seed(seed:SeedDataExpression):String {
		final table = Table(seed.TableName, seed.Schema);
		final where = [for (k in seed.KeyColumns) '$k = ${seed.Values.get(k)}'].join(" AND ");

		return switch seed.Operation {
			case Insert:
				final values = [for (c in seed.Columns) seed.Values.get(c)].join(", ");
				'INSERT INTO $table (${seed.Columns.join(", ")}) VALUES ($values)';
			case Update:
				final assignments = [
					for (c in seed.Columns)
						if (seed.KeyColumns.indexOf(c) < 0) '$c = ${seed.Values.get(c)}'
				].join(", ");
				'UPDATE $table SET $assignments WHERE $where';
			case Delete:
				'DELETE FROM $table WHERE $where';
		}
	}

	// ---- naming ------------------------------------------------------------------------------------

	static function Table(name:String, schema:Null<String>):String {
		return schema == null || schema == "" ? name : '$schema.$name';
	}

	static function CascadeClause(cascade:Bool):String {
		return cascade ? " CASCADE" : "";
	}
}
