package codequery.migrations;

/** What decides whether an add and a drop of the same shape were a rename. */
interface IMigrationPrompt {
	/** The dropped table `addedTable` was renamed from, or null for none of them. */
	function ResolveTableRename(addedTable:String, droppedCandidates:Array<String>):Null<String>;

	/** The dropped column `addedColumn` was renamed from, or null for none of them. */
	function ResolveColumnRename(tableName:String, addedColumn:String, droppedCandidates:Array<String>):Null<String>;
}

/** Nobody to ask: an ambiguous add and drop stays an add and a drop. */
class NonInteractiveMigrationPrompt implements IMigrationPrompt {
	public function new() {}

	public function ResolveTableRename(addedTable:String, droppedCandidates:Array<String>):Null<String> {
		return null;
	}

	public function ResolveColumnRename(tableName:String, addedColumn:String, droppedCandidates:Array<String>):Null<String> {
		return null;
	}
}

/**
	Remembers what the prompt decided, so the reverse plan can answer the same questions the other
	way round: a rename up is the opposite rename down.
**/
class RecordingMigrationPrompt implements IMigrationPrompt {
	final inner:IMigrationPrompt;
	final tables:Array<{from:String, to:String}> = [];
	final columns:Array<{table:String, from:String, to:String}> = [];

	public function new(inner:IMigrationPrompt) {
		this.inner = inner;
	}

	public function ResolveTableRename(addedTable:String, droppedCandidates:Array<String>):Null<String> {
		final answer = inner.ResolveTableRename(addedTable, droppedCandidates);
		if (answer != null) {
			tables.push({from: answer, to: addedTable});
		}
		return answer;
	}

	public function ResolveColumnRename(tableName:String, addedColumn:String, droppedCandidates:Array<String>):Null<String> {
		final answer = inner.ResolveColumnRename(tableName, addedColumn, droppedCandidates);
		if (answer != null) {
			columns.push({table: tableName, from: answer, to: addedColumn});
		}
		return answer;
	}

	/** The same decisions, inverted. */
	public function Inverse():IMigrationPrompt {
		return new InverseMigrationPrompt(tables, columns);
	}
}

private class InverseMigrationPrompt implements IMigrationPrompt {
	final tables:Array<{from:String, to:String}>;
	final columns:Array<{table:String, from:String, to:String}>;

	public function new(tables:Array<{from:String, to:String}>, columns:Array<{table:String, from:String, to:String}>) {
		this.tables = tables;
		this.columns = columns;
	}

	public function ResolveTableRename(addedTable:String, droppedCandidates:Array<String>):Null<String> {
		for (rename in tables) {
			if (rename.from == addedTable && droppedCandidates.indexOf(rename.to) >= 0) {
				return rename.to;
			}
		}
		return null;
	}

	public function ResolveColumnRename(tableName:String, addedColumn:String, droppedCandidates:Array<String>):Null<String> {
		for (rename in columns) {
			if (rename.from == addedColumn && droppedCandidates.indexOf(rename.to) >= 0) {
				return rename.to;
			}
		}
		return null;
	}
}
