package codequery.migrations;

import codequery.migrations.DatabaseColumnType;
import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.SchemaDiff;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.TableConstraint;

/**
	Turns a diff into an ordered list of operations, asking a prompt about the renames a pure diff
	cannot infer — an add and a drop of the same shape may be one column renamed.
**/
class MigrationPlanner {
	/**
		The operations that take a schema from one shape to the other.

		`liftForeignKeys` creates every table first and adds the foreign keys after, rather than
		writing them into the CREATE TABLE: two tables that point at each other cannot be ordered,
		but added afterwards there is nothing to order. Dropping is the same problem backwards, so
		the keys come off before the tables go.
	**/
	public static function Plan(diff:SchemaDiff, prompt:IMigrationPrompt, liftForeignKeys:Bool = false):Array<SchemaChangeExpression> {
		final ops:Array<SchemaChangeExpression> = [];
		final lifted:Array<SchemaChangeExpression> = [];

		// Types — before any table that may reference them; a changed one is dropped and remade.
		for (type in diff.AddedTypes) {
			ops.push(CreateType(type));
		}
		for (pair in diff.ModifiedTypes) {
			ops.push(new DropTypeExpression(pair.From.Name, pair.From.Schema, true, pair.From.IsDomain));
			ops.push(CreateType(pair.To));
		}

		final addedTables = diff.AddedTables.copy();
		final removedTables = diff.RemovedTables.copy();

		// 1. Table renames: an added table that structurally matches a removed one.
		for (added in addedTables.copy()) {
			final candidates = [for (r in removedTables) if (StructureMatches(r, added)) r];
			if (candidates.length == 0) {
				continue;
			}
			final oldName = prompt.ResolveTableRename(added.Name, [for (c in candidates) c.Name]);
			if (oldName == null) {
				continue;
			}
			var old:DatabaseTableDefinition = null;
			for (c in candidates) {
				if (c.Name == oldName) {
					old = c;
				}
			}
			ops.push(new RenameTableExpression(old.Name, added.Name, added.Schema));
			for (op in added.Diff(WithName(old, added.Name))) {
				ops.push(op);
			}
			addedTables.remove(added);
			removedTables.remove(old);
		}

		// 2. New tables, parents before the children whose keys point at them.
		for (added in OrderByForeignKeyDependencies(addedTables)) {
			final created = added.Diff(null);
			final emitted = liftForeignKeys ? LiftForeignKeys(created, lifted) : created;
			for (op in emitted) {
				ops.push(op);
			}
		}

		// 3. Modified tables.
		for (tableDiff in diff.ModifiedTables) {
			for (op in PlanTable(tableDiff, prompt)) {
				ops.push(op);
			}
		}

		// 3b. Routines going away are dropped before the tables they may read.
		for (routine in diff.RemovedRoutines) {
			ops.push(new DropRoutineExpression(routine.Kind, routine.Name, routine.Schema, false, routine.TableName));
		}

		// 4. Dropped tables, children before parents. A key added by an ALTER comes off by one.
		if (liftForeignKeys) {
			for (removed in removedTables) {
				for (constraint in removed.Constraints) {
					final fk = Std.downcast(constraint, DatabaseForeignKeyConstraint);
					if (fk != null && fk.Name != null && fk.Name != "") {
						ops.push(new DropConstraintExpression(removed.Name, fk.Name, removed.Schema));
					}
				}
			}
		}
		final dropped = OrderByForeignKeyDependencies(removedTables);
		dropped.reverse();
		for (removed in dropped) {
			ops.push(new DropTableExpression(removed.Name, removed.Schema, true));
		}

		// 5. Routines created or replaced, once the tables they read exist. The inline ones are not
		// among them — the application creates those when it runs.
		for (routine in diff.AddedRoutines) {
			if (!routine.Inline) {
				ops.push(new CreateRoutineExpression(routine.Kind, routine.Name, routine.Schema, routine.Body));
			}
		}
		for (pair in diff.ModifiedRoutines) {
			if (!pair.To.Inline) {
				ops.push(new CreateRoutineExpression(pair.To.Kind, pair.To.Name, pair.To.Schema, pair.To.Body));
			}
		}

		// 6. Seed data.
		for (seed in diff.SeedChanges) {
			ops.push(seed);
		}

		// 7. Removed types — after the tables that referenced them are gone.
		for (type in diff.RemovedTypes) {
			ops.push(new DropTypeExpression(type.Name, type.Schema, true, type.IsDomain));
		}

		// Every table named by one of these now exists, whichever order they were created in.
		for (op in lifted) {
			ops.push(op);
		}
		return ops;
	}

	static function CreateType(type:DatabaseObjectTypeDefinition):SchemaChangeExpression {
		// This port has no CREATE TYPE statement of its own; the change is recorded as the SQL it is.
		final fields = [for (f in type.Fields) '${f.Name} ${Std.string(f.Type).toUpperCase()}'].join(", ");
		final sql = type.EnumValues != null
			? 'CREATE TYPE ${type.Name} AS ENUM (${[for (v in type.EnumValues) "\'" + v + "\'"].join(", ")})'
			: 'CREATE TYPE ${type.Name} AS ($fields)';
		return new StatementExpression(type.Name, sql);
	}

	static function PlanTable(diff:TableDiff, prompt:IMigrationPrompt):Array<SchemaChangeExpression> {
		final table = diff.ToTable.Name;
		final schema = diff.ToTable.Schema;
		final ops:Array<SchemaChangeExpression> = [];

		final addedCols = diff.AddedColumns.copy();
		final removedCols = diff.RemovedColumns.copy();

		// Ordinal-based renames: a removed and an added column at the same ordinal are the same
		// logical column renamed, when the type change can be applied in place — decided from the
		// snapshot alone, with no prompt.
		for (added in addedCols.copy()) {
			if (added.OrdinalIndex == null) {
				continue;
			}
			var old:DatabaseColumnDefinition = null;
			for (r in removedCols) {
				if (r.OrdinalIndex == added.OrdinalIndex) {
					old = r;
					break;
				}
			}
			if (old == null || !IsAlterCompatible(old, added)) {
				continue;
			}
			ops.push(new RenameColumnExpression(table, old.Name, added.Name, schema));
			if (!ColumnsEqualIgnoringName(old, added)) {
				ops.push(new AlterColumnExpression(table, added.Name, added.ToColumnDefinition(), old.ToColumnDefinition(), schema));
			}
			addedCols.remove(added);
			removedCols.remove(old);
		}

		// Column renames the prompt decides: an added column against the removed ones of its type.
		for (added in addedCols.copy()) {
			final candidates = [for (r in removedCols) if (Std.string(r.Type) == Std.string(added.Type)) r.Name];
			if (candidates.length == 0) {
				continue;
			}
			final oldName = prompt.ResolveColumnRename(table, added.Name, candidates);
			if (oldName == null) {
				continue;
			}
			var old:DatabaseColumnDefinition = null;
			for (r in removedCols) {
				if (r.Name == oldName) {
					old = r;
				}
			}
			ops.push(new RenameColumnExpression(table, old.Name, added.Name, schema));
			if (!ColumnsEqualIgnoringName(old, added)) {
				ops.push(new AlterColumnExpression(table, added.Name, added.ToColumnDefinition(), old.ToColumnDefinition(), schema));
			}
			addedCols.remove(added);
			removedCols.remove(old);
		}

		// Drop dependent objects before columns, then add columns, then re-create objects.
		for (index in diff.RemovedIndexes) {
			ops.push(new DropIndexExpression(table, index.Name, schema));
		}
		for (constraint in diff.RemovedConstraints) {
			if (constraint.Name != null) {
				ops.push(new DropConstraintExpression(table, constraint.Name, schema));
			}
		}
		for (column in removedCols) {
			ops.push(new DropColumnExpression(table, column.Name, schema));
		}
		// A column arriving NOT NULL has to say what the rows already there hold.
		for (column in addedCols) {
			ops.push(Added(table, column, schema));
		}
		for (pair in diff.ModifiedColumns) {
			ops.push(new AlterColumnExpression(table, pair.To.Name, pair.To.ToColumnDefinition(), pair.From.ToColumnDefinition(), schema));
		}
		for (constraint in diff.AddedConstraints) {
			ops.push(new AddConstraintExpression(table, constraint.ToTableConstraint(), schema));
		}
		for (index in diff.AddedIndexes) {
			ops.push(index.ToCreateIndexExpression(table, schema));
		}
		return ops;
	}

	/** A column added to a table that already exists, with what its existing rows take. */
	static function Added(table:String, column:DatabaseColumnDefinition, schema:Null<String>):AddColumnExpression {
		final definition = column.ToColumnDefinition();
		return new AddColumnExpression(table, definition, schema, ColumnBackfill.For(definition));
	}

	/**
		Takes the foreign keys out of a CREATE TABLE and puts them aside, leaving a note on each
		column so the table still shows what it points at.
	**/
	static function LiftForeignKeys(operations:Array<SchemaChangeExpression>, lifted:Array<SchemaChangeExpression>):Array<SchemaChangeExpression> {
		final out:Array<SchemaChangeExpression> = [];
		for (operation in operations) {
			final create = Std.downcast(operation, CreateTableExpression);
			final keys = create == null ? [] : [for (c in create.Constraints) if (Std.isOfType(c, ForeignKeyConstraint)) (cast c : ForeignKeyConstraint)];
			if (create == null || keys.length == 0) {
				out.push(operation);
				continue;
			}
			for (fk in keys) {
				lifted.push(new AddConstraintExpression(create.TableName, fk, create.Schema));
				// One column is the ordinary case; a composite key notes its first.
				for (column in create.Columns) {
					if (fk.Columns.length > 0 && column.Name.toLowerCase() == fk.Columns[0].toLowerCase()) {
						column.ReferencesNote = '${fk.ReferencedTable} (${fk.ReferencedColumns.join(", ")})';
					}
				}
			}
			out.push(new CreateTableExpression(create.TableName, create.Columns,
				[for (c in create.Constraints) if (!Std.isOfType(c, ForeignKeyConstraint)) c],
				create.Schema, create.IfNotExists, create.Partition));
		}
		return out;
	}

	/**
		Orders the tables so each follows every other table in the set that it references — parents
		before children. Only references within the set impose an order; a cycle is broken by
		falling back to the input order for the tables involved.
	**/
	public static function OrderByForeignKeyDependencies(tables:Array<DatabaseTableDefinition>):Array<DatabaseTableDefinition> {
		if (tables.length < 2) {
			return tables.copy();
		}
		final present = [for (t in tables) TableKey(t.Schema, t.Name).toLowerCase()];
		final dependencies = new Map<String, Array<String>>();
		for (t in tables) {
			final self = TableKey(t.Schema, t.Name).toLowerCase();
			final needs:Array<String> = [];
			for (c in t.Constraints) {
				final fk = Std.downcast(c, DatabaseForeignKeyConstraint);
				if (fk == null) {
					continue;
				}
				final key = TableKey(fk.ReferencedSchema == null ? t.Schema : fk.ReferencedSchema, fk.ReferencedTable).toLowerCase();
				if (present.indexOf(key) >= 0 && key != self && needs.indexOf(key) < 0) {
					needs.push(key);
				}
			}
			dependencies.set(self, needs);
		}

		final emitted:Array<String> = [];
		final ordered:Array<DatabaseTableDefinition> = [];
		while (ordered.length < tables.length) {
			var next:DatabaseTableDefinition = null;
			for (t in tables) {
				final key = TableKey(t.Schema, t.Name).toLowerCase();
				if (emitted.indexOf(key) >= 0) {
					continue;
				}
				var free = true;
				for (need in dependencies.get(key)) {
					if (emitted.indexOf(need) < 0) {
						free = false;
					}
				}
				if (free) {
					next = t;
					break;
				}
			}
			if (next == null) {
				for (t in tables) {
					if (emitted.indexOf(TableKey(t.Schema, t.Name).toLowerCase()) < 0) {
						next = t;
						break;
					}
				}
			}
			ordered.push(next);
			emitted.push(TableKey(next.Schema, next.Name).toLowerCase());
		}
		return ordered;
	}

	static function StructureMatches(a:DatabaseTableDefinition, b:DatabaseTableDefinition):Bool {
		final ac = [for (c in a.Columns) c.Name + ":" + Std.string(c.Type)];
		final bc = [for (c in b.Columns) c.Name + ":" + Std.string(c.Type)];
		ac.sort(SchemaCanonicalizer.Compare);
		bc.sort(SchemaCanonicalizer.Compare);
		return ac.join("\n") == bc.join("\n");
	}

	static function WithName(table:DatabaseTableDefinition, name:String):DatabaseTableDefinition {
		final renamed = new DatabaseTableDefinition(name, table.Columns, table.Schema);
		renamed.Constraints = table.Constraints;
		renamed.Indexes = table.Indexes;
		return renamed;
	}

	static function ColumnsEqualIgnoringName(a:DatabaseColumnDefinition, b:DatabaseColumnDefinition):Bool {
		return Std.string(a.Type) == Std.string(b.Type)
			&& a.Nullable == b.Nullable
			&& a.IsAutoIncrement == b.IsAutoIncrement
			&& Std.string(a.Identity) == Std.string(b.Identity)
			&& a.DefaultValue == b.DefaultValue
			&& a.MaxLength == b.MaxLength
			&& a.Precision == b.Precision
			&& a.Scale == b.Scale
			&& a.Collation == b.Collation;
	}

	/**
		Whether the change can be applied with an in-place ALTER COLUMN without data loss: the same
		type always; a different type only as a lossless widening within its family.
	**/
	static function IsAlterCompatible(from:DatabaseColumnDefinition, to:DatabaseColumnDefinition):Bool {
		if (Std.string(from.Type) == Std.string(to.Type)) {
			return true;
		}
		final was = WideningRank(from.Type);
		final now = WideningRank(to.Type);
		return was.family != "" && was.family == now.family && now.order >= was.order;
	}

	static function WideningRank(type:DatabaseColumnType):{family:String, order:Int} {
		return switch type {
			case TinyInt: {family: "integer", order: 1};
			case SmallInt: {family: "integer", order: 2};
			case Int: {family: "integer", order: 3};
			case BigInt: {family: "integer", order: 4};
			case Float: {family: "real", order: 1};
			case Double: {family: "real", order: 2};
			case Decimal: {family: "real", order: 3};
			case Char | NChar: {family: "text", order: 1};
			case VarChar | NVarChar: {family: "text", order: 2};
			case Text | NText: {family: "text", order: 3};
			case Binary: {family: "binary", order: 1};
			case VarBinary: {family: "binary", order: 2};
			case Blob: {family: "binary", order: 3};
			case _: {family: "", order: 0};
		}
	}

	static function TableKey(schema:Null<String>, name:String):String {
		return schema == null || schema == "" ? name : '$schema.$name';
	}
}
