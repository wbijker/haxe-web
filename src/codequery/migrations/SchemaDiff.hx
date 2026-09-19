package codequery.migrations;

import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.DatabaseIndexDefinition;
import codequery.sqlexpressions.SchemaChangeExpression;

/** What has to happen to turn one schema into another. */
class SchemaDiff {
	// ---- the C# SchemaDiff: what differs, by kind, for the planner to order --------------------------

	public final From:Null<DatabaseSchema>;
	public final To:DatabaseSchema;

	public final AddedTables:Array<DatabaseTableDefinition> = [];
	public final RemovedTables:Array<DatabaseTableDefinition> = [];
	public final ModifiedTables:Array<TableDiff> = [];

	public final AddedRoutines:Array<DatabaseRoutineDefinition> = [];
	public final RemovedRoutines:Array<DatabaseRoutineDefinition> = [];
	public final ModifiedRoutines:Array<{From:DatabaseRoutineDefinition, To:DatabaseRoutineDefinition}> = [];

	public final AddedTypes:Array<DatabaseObjectTypeDefinition> = [];
	public final RemovedTypes:Array<DatabaseObjectTypeDefinition> = [];
	public final ModifiedTypes:Array<{From:DatabaseObjectTypeDefinition, To:DatabaseObjectTypeDefinition}> = [];

	/** Seed-row changes (insert/update/delete) required to reach `To`. */
	public final SeedChanges:Array<SeedDataExpression> = [];

	public var HasChanges(get, never):Bool;

	function get_HasChanges():Bool {
		return AddedTables.length > 0 || RemovedTables.length > 0 || ModifiedTables.length > 0
			|| AddedRoutines.length > 0 || RemovedRoutines.length > 0 || ModifiedRoutines.length > 0
			|| AddedTypes.length > 0 || RemovedTypes.length > 0 || ModifiedTypes.length > 0
			|| SeedChanges.length > 0;
	}

	function new(from:Null<DatabaseSchema>, to:DatabaseSchema) {
		this.From = from;
		this.To = to;
	}

	/** The differences between two snapshots; a null `from` is the empty schema. */
	public static function Create(from:Null<DatabaseSchema>, to:DatabaseSchema):SchemaDiff {
		final diff = new SchemaDiff(from, to);
		diff.Compute();
		return diff;
	}

	function Compute():Void {
		final fromTables = From == null ? [] : From.Tables;

		for (table in To.Tables) {
			final was = Find(fromTables, table);
			if (was == null) {
				AddedTables.push(table);
			} else {
				final tableDiff = TableDiff.Create(was, table);
				if (tableDiff.HasChanges) {
					ModifiedTables.push(tableDiff);
				}
			}
		}
		for (table in fromTables) {
			if (Find(To.Tables, table) == null) {
				RemovedTables.push(table);
			}
		}

		ComputeRoutineDiff();
		ComputeTypeDiff();
		ComputeSeedDiff();
	}

	static function Find(tables:Array<DatabaseTableDefinition>, wanted:DatabaseTableDefinition):Null<DatabaseTableDefinition> {
		for (table in tables) {
			if (TableKey(table.Name, table.Schema).toLowerCase() == TableKey(wanted.Name, wanted.Schema).toLowerCase()) {
				return table;
			}
		}
		return null;
	}

	function ComputeRoutineDiff():Void {
		final fromRoutines = From == null ? [] : From.Routines;
		for (to in To.Routines) {
			final was = FindRoutine(fromRoutines, to);
			if (was == null) {
				AddedRoutines.push(to);
			} else if (RoutineChanged(was, to)) {
				ModifiedRoutines.push({From: was, To: to});
			}
		}
		for (from in fromRoutines) {
			if (FindRoutine(To.Routines, from) == null) {
				RemovedRoutines.push(from);
			}
		}
	}

	static function FindRoutine(routines:Array<DatabaseRoutineDefinition>, wanted:DatabaseRoutineDefinition):Null<DatabaseRoutineDefinition> {
		for (routine in routines) {
			if (Std.string(routine.Kind) == Std.string(wanted.Kind)
				&& TableKey(routine.Name, routine.Schema).toLowerCase() == TableKey(wanted.Name, wanted.Schema).toLowerCase()) {
				return routine;
			}
		}
		return null;
	}

	/** A routine is changed when its body, its materialized flag, its inlining or its return type differs. */
	static function RoutineChanged(from:DatabaseRoutineDefinition, to:DatabaseRoutineDefinition):Bool {
		return from.Body != to.Body || from.Materialized != to.Materialized || from.Inline != to.Inline
			|| from.ReturnType != to.ReturnType;
	}

	function ComputeTypeDiff():Void {
		final fromTypes = From == null ? [] : From.Types;
		for (to in To.Types) {
			final was = FindType(fromTypes, to);
			if (was == null) {
				AddedTypes.push(to);
			} else if (!to.Equals(was)) {
				ModifiedTypes.push({From: was, To: to});
			}
		}
		for (from in fromTypes) {
			if (FindType(To.Types, from) == null) {
				RemovedTypes.push(from);
			}
		}
	}

	static function FindType(types:Array<DatabaseObjectTypeDefinition>, wanted:DatabaseObjectTypeDefinition):Null<DatabaseObjectTypeDefinition> {
		for (type in types) {
			if (TableKey(type.Name, type.Schema).toLowerCase() == TableKey(wanted.Name, wanted.Schema).toLowerCase()) {
				return type;
			}
		}
		return null;
	}

	function ComputeSeedDiff():Void {
		final fromSeeds = From == null ? [] : From.Seeds;
		for (to in To.Seeds) {
			DiffSeedTable(FindSeed(fromSeeds, to.TableName, to.Schema), to);
		}
		// A seed set removed from the schema deletes its rows.
		for (from in fromSeeds) {
			if (FindSeed(To.Seeds, from.TableName, from.Schema) == null) {
				final empty = new SeedDataDefinition(from.TableName, from.Schema);
				empty.KeyColumns = from.KeyColumns;
				empty.Columns = from.Columns;
				DiffSeedTable(from, empty);
			}
		}
	}

	static function FindSeed(seeds:Array<SeedDataDefinition>, table:String, schema:Null<String>):Null<SeedDataDefinition> {
		for (seed in seeds) {
			if (seed.TableName.toLowerCase() == table.toLowerCase() && seed.Schema == schema) {
				return seed;
			}
		}
		return null;
	}

	function DiffSeedTable(from:Null<SeedDataDefinition>, to:SeedDataDefinition):Void {
		final fromRows = new Map<String, Map<String, String>>();
		final fromKeys:Array<String> = [];
		if (from != null) {
			for (row in from.Rows) {
				final key = RowKey(to, row);
				fromRows.set(key, row);
				fromKeys.push(key);
			}
		}

		final toKeys:Array<String> = [];
		for (row in to.Rows) {
			final key = RowKey(to, row);
			toKeys.push(key);
			final existing = fromRows.get(key);
			if (existing == null) {
				SeedChanges.push(new SeedDataExpression(Insert, to.TableName, to.Schema, to.Columns, to.KeyColumns, row));
			} else {
				var same = true;
				for (c in to.Columns) {
					if (Cell(existing, c) != Cell(row, c)) {
						same = false;
					}
				}
				if (!same) {
					SeedChanges.push(new SeedDataExpression(Update, to.TableName, to.Schema, to.Columns, to.KeyColumns, row));
				}
			}
		}

		for (key in fromKeys) {
			if (toKeys.indexOf(key) < 0) {
				SeedChanges.push(new SeedDataExpression(Delete, to.TableName, to.Schema, to.Columns, to.KeyColumns, fromRows.get(key)));
			}
		}
	}

	static function Cell(row:Map<String, String>, column:String):String {
		return row.exists(column) ? row.get(column) : "NULL";
	}

	static function RowKey(seed:SeedDataDefinition, row:Map<String, String>):String {
		return [for (k in seed.KeyColumns) Cell(row, k)].join("");
	}

	static function TableKey(name:String, schema:Null<String>):String {
		return schema == null || schema == "" ? name : '$schema.$name';
	}

	// ---- the enum form this port started with ------------------------------------------------------

	/**
		The changes from `from` to `to`.

		Tables are created before columns are added to them and dropped after their columns, so the
		list can be applied in the order it comes in.
	**/
	public static function Between(from:DatabaseSchema, to:DatabaseSchema):Array<SchemaChange> {
		final changes:Array<SchemaChange> = [];

		for (table in to.Tables) {
			final existing = from.Table(table.Name);
			if (existing == null) {
				changes.push(CreateTable(table));
				continue;
			}

			for (column in table.Columns) {
				final had = existing.Column(column.Name);
				if (had == null) {
					changes.push(AddColumn(table.Name, column));
				} else if (!had.Matches(column)) {
					changes.push(AlterColumn(table.Name, had, column));
				}
			}

			for (column in existing.Columns) {
				if (table.Column(column.Name) == null) {
					changes.push(DropColumn(table.Name, column));
				}
			}
		}

		for (table in from.Tables) {
			if (to.Table(table.Name) == null) {
				changes.push(DropTable(table));
			}
		}

		return changes;
	}

	/** The same change, the other way round — what undoes it. */
	public static function Reverse(change:SchemaChange):SchemaChange {
		return switch change {
			case CreateTable(table): DropTable(table);
			case DropTable(table): CreateTable(table);
			case AddColumn(table, column): DropColumn(table, column);
			case DropColumn(table, column): AddColumn(table, column);
			case AlterColumn(table, from, to): AlterColumn(table, to, from);
		}
	}
}

/** The differences within a single table. */
class TableDiff {
	public final FromTable:DatabaseTableDefinition;
	public final ToTable:DatabaseTableDefinition;

	public final AddedColumns:Array<DatabaseColumnDefinition> = [];
	public final RemovedColumns:Array<DatabaseColumnDefinition> = [];
	public final ModifiedColumns:Array<{From:DatabaseColumnDefinition, To:DatabaseColumnDefinition}> = [];

	public final AddedConstraints:Array<DatabaseTableConstraint> = [];
	public final RemovedConstraints:Array<DatabaseTableConstraint> = [];

	public final AddedIndexes:Array<DatabaseIndexDefinition> = [];
	public final RemovedIndexes:Array<DatabaseIndexDefinition> = [];

	public var HasChanges(get, never):Bool;

	function get_HasChanges():Bool {
		return AddedColumns.length > 0 || RemovedColumns.length > 0 || ModifiedColumns.length > 0
			|| AddedConstraints.length > 0 || RemovedConstraints.length > 0
			|| AddedIndexes.length > 0 || RemovedIndexes.length > 0;
	}

	function new(from:DatabaseTableDefinition, to:DatabaseTableDefinition) {
		this.FromTable = from;
		this.ToTable = to;
	}

	public static function Create(from:DatabaseTableDefinition, to:DatabaseTableDefinition):TableDiff {
		final diff = new TableDiff(from, to);
		diff.ComputeColumnDiff();
		diff.ComputeConstraintDiff();
		diff.ComputeIndexDiff();
		return diff;
	}

	/**
		The table's columns by name, or an error saying which table and which name when two of them
		share one. A duplicate is a broken model rather than a schema change, and every one of those
		things is known here.
	**/
	static function ColumnsByName(table:DatabaseTableDefinition, side:String):Map<String, DatabaseColumnDefinition> {
		final byName = new Map<String, DatabaseColumnDefinition>();
		for (column in table.Columns) {
			final key = column.Name.toLowerCase();
			if (byName.exists(key)) {
				throw 'Table \'${table.Name}\' declares the column \'${column.Name}\' more than once in the $side schema, '
					+ 'so it cannot be compared. Two properties mapping to one column name, or a configuration adding a '
					+ 'column inspection already found, are what usually cause it.';
			}
			byName.set(key, column);
		}
		return byName;
	}

	function ComputeColumnDiff():Void {
		final fromColumns = ColumnsByName(FromTable, "source");
		final toColumns = ColumnsByName(ToTable, "target");

		for (column in ToTable.Columns) {
			final was = fromColumns.get(column.Name.toLowerCase());
			if (was == null) {
				AddedColumns.push(column);
			} else if (!was.Matches(column)) {
				ModifiedColumns.push({From: was, To: column});
			}
		}
		for (column in FromTable.Columns) {
			if (!toColumns.exists(column.Name.toLowerCase())) {
				RemovedColumns.push(column);
			}
		}
	}

	function ComputeConstraintDiff():Void {
		for (constraint in ToTable.Constraints) {
			if (constraint.Name == null) {
				continue;
			}
			final was = Named(FromTable.Constraints, constraint.Name);
			if (was == null) {
				AddedConstraints.push(constraint);
			} else if (!constraint.Equals(was)) {
				RemovedConstraints.push(was);
				AddedConstraints.push(constraint);
			}
		}
		for (constraint in FromTable.Constraints) {
			if (constraint.Name != null && Named(ToTable.Constraints, constraint.Name) == null) {
				RemovedConstraints.push(constraint);
			}
		}
	}

	static function Named(constraints:Array<DatabaseTableConstraint>, name:String):Null<DatabaseTableConstraint> {
		for (constraint in constraints) {
			if (constraint.Name != null && constraint.Name.toLowerCase() == name.toLowerCase()) {
				return constraint;
			}
		}
		return null;
	}

	function ComputeIndexDiff():Void {
		for (index in ToTable.Indexes) {
			final was = IndexNamed(FromTable.Indexes, index.Name);
			if (was == null) {
				AddedIndexes.push(index);
			} else if (!index.Equals(was)) {
				RemovedIndexes.push(was);
				AddedIndexes.push(index);
			}
		}
		for (index in FromTable.Indexes) {
			if (IndexNamed(ToTable.Indexes, index.Name) == null) {
				RemovedIndexes.push(index);
			}
		}
	}

	static function IndexNamed(indexes:Array<DatabaseIndexDefinition>, name:String):Null<DatabaseIndexDefinition> {
		for (index in indexes) {
			if (index.Name.toLowerCase() == name.toLowerCase()) {
				return index;
			}
		}
		return null;
	}
}
