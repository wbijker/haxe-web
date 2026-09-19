package codequery.migrations;

/** What has to happen to turn one schema into another. */
class SchemaDiff {
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

		// A view reads tables, so it is made after them and dropped before them.
		for (view in to.Views) {
			final existing = from.View(view.Name);
			if (existing == null) {
				changes.push(CreateView(view));
			} else if (!existing.Matches(view)) {
				changes.push(AlterView(existing, view));
			}
		}
		for (view in from.Views) {
			if (to.View(view.Name) == null) {
				changes.push(DropView(view));
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
			case CreateView(view): DropView(view);
			case DropView(view): CreateView(view);
			case AlterView(from, to): AlterView(to, from);
		}
	}
}
