package codequery.migrations;

/**
	A deterministic, order-independent form of a schema: every collection sorted by a stable key,
	the volatile metadata dropped. Two schemas with the same structure serialize identically
	whatever order their tables were found in — so a snapshot stays stable across runs, and the
	fingerprint compares two schemas structurally.
**/
class SchemaCanonicalizer {
	/** A short, deterministic hash of the schema's structure: a SHA-256 of its canonical form. */
	public static function Fingerprint(schema:DatabaseSchema):String {
		return haxe.crypto.Sha256.encode(SnapshotSerializer.Serialize(SchemaSnapshotDocument.FromModel(Canonical(schema))));
	}

	/** A deep, canonically-ordered clone of the schema. */
	public static function Canonical(schema:DatabaseSchema):DatabaseSchema {
		final tables = [for (t in schema.Tables) CanonicalTable(t.Clone())];
		tables.sort((a, b) -> Compare(Key(a.Schema, a.Name), Key(b.Schema, b.Name)));

		final types = [for (t in schema.Types) t.Clone()];
		for (t in types) {
			t.Fields = SortColumns(t.Fields);
		}
		types.sort((a, b) -> Compare(Key(a.Schema, a.Name), Key(b.Schema, b.Name)));

		final routines = [for (r in schema.Routines) r.Clone()];
		routines.sort((a, b) -> Compare(Std.string(a.Kind) + ":" + Key(a.Schema, a.Name), Std.string(b.Kind) + ":" + Key(b.Schema, b.Name)));

		final seeds = [for (s in schema.Seeds) CanonicalSeed(s)];
		seeds.sort((a, b) -> Compare(Key(a.Schema, a.TableName), Key(b.Schema, b.TableName)));

		final canonical = new DatabaseSchema(tables, null, 1);
		canonical.Types = types;
		canonical.Routines = routines;
		canonical.Seeds = seeds;
		return canonical;
	}

	static function CanonicalTable(t:DatabaseTableDefinition):DatabaseTableDefinition {
		t.Columns = SortColumns(t.Columns);
		t.Constraints.sort((a, b) -> {
			final byKind = Compare(Std.string(a.ConstraintType()), Std.string(b.ConstraintType()));
			byKind != 0 ? byKind : Compare(a.Name == null ? "" : a.Name, b.Name == null ? "" : b.Name);
		});
		t.Indexes.sort((a, b) -> Compare(a.Name, b.Name));
		return t;
	}

	/** Columns keep their semantic order (ordinal), with name as a stable tie-breaker. */
	static function SortColumns(columns:Array<DatabaseColumnDefinition>):Array<DatabaseColumnDefinition> {
		final sorted = columns.copy();
		sorted.sort((a, b) -> {
			final x = a.OrdinalIndex == null ? 0x7fffffff : a.OrdinalIndex;
			final y = b.OrdinalIndex == null ? 0x7fffffff : b.OrdinalIndex;
			x != y ? (x < y ? -1 : 1) : Compare(a.Name, b.Name);
		});
		return sorted;
	}

	static function CanonicalSeed(s:SeedDataDefinition):SeedDataDefinition {
		final seed = new SeedDataDefinition(s.TableName, s.Schema);
		seed.KeyColumns = s.KeyColumns.copy();
		seed.Columns = s.Columns.copy();
		final rows = s.Rows.copy();
		rows.sort((a, b) -> Compare(RowKey(s, a), RowKey(s, b)));
		seed.Rows = [
			for (row in rows) {
				final cells = new Map<String, String>();
				for (c in s.Columns) {
					if (row.exists(c)) {
						cells.set(c, row.get(c));
					}
				}
				cells;
			}
		];
		return seed;
	}

	static function RowKey(s:SeedDataDefinition, row:Map<String, String>):String {
		return [for (k in s.KeyColumns) row.exists(k) ? row.get(k) : "NULL"].join("");
	}

	static function Key(schema:Null<String>, name:String):String {
		return schema == null || schema == "" ? name : '$schema.$name';
	}

	public static function Compare(a:String, b:String):Int {
		return a < b ? -1 : (a > b ? 1 : 0);
	}
}
