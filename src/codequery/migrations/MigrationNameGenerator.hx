package codequery.migrations;

/**
	A human-readable name for a diff:
	- first migration           → "Initial"
	- 1 table, 1 column change  → "Add|Drop|Alter column [Col] on [Table]"
	- 1 table, several changes  → "Alter table [Table]"
	- several tables            → "Multiple database changes"
	- no table, 1 type change   → "Add|Drop|Alter type [Type]"
**/
class MigrationNameGenerator {
	public static function Generate(diff:SchemaDiff, isFirstMigration:Bool):String {
		if (isFirstMigration) {
			return "Initial";
		}

		final affected = diff.AddedTables.length + diff.RemovedTables.length + diff.ModifiedTables.length;

		if (affected == 0) {
			final types = DescribeTypeChanges(diff);
			return types == null ? "No changes" : types;
		}
		if (affected > 1) {
			return "Multiple database changes";
		}
		if (diff.AddedTables.length == 1) {
			return 'Alter table ${diff.AddedTables[0].Name}';
		}
		if (diff.RemovedTables.length == 1) {
			return 'Alter table ${diff.RemovedTables[0].Name}';
		}

		final modified = diff.ModifiedTables[0];
		final columnChanges = modified.AddedColumns.length + modified.RemovedColumns.length + modified.ModifiedColumns.length;
		final otherChanges = modified.AddedConstraints.length + modified.RemovedConstraints.length
			+ modified.AddedIndexes.length + modified.RemovedIndexes.length;

		if (columnChanges == 1 && otherChanges == 0) {
			if (modified.AddedColumns.length == 1) {
				return 'Add column ${modified.AddedColumns[0].Name} on ${modified.ToTable.Name}';
			}
			if (modified.RemovedColumns.length == 1) {
				return 'Drop column ${modified.RemovedColumns[0].Name} on ${modified.ToTable.Name}';
			}
			return 'Alter column ${modified.ModifiedColumns[0].To.Name} on ${modified.ToTable.Name}';
		}

		return 'Alter table ${modified.ToTable.Name}';
	}

	static function DescribeTypeChanges(diff:SchemaDiff):Null<String> {
		final affected = diff.AddedTypes.length + diff.RemovedTypes.length + diff.ModifiedTypes.length;
		if (affected == 0) {
			return null;
		}
		if (affected > 1) {
			return "Multiple database changes";
		}
		if (diff.AddedTypes.length == 1) {
			return 'Add type ${diff.AddedTypes[0].Name}';
		}
		if (diff.RemovedTypes.length == 1) {
			return 'Drop type ${diff.RemovedTypes[0].Name}';
		}
		return 'Alter type ${diff.ModifiedTypes[0].To.Name}';
	}
}
