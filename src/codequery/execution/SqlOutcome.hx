package codequery.execution;

/** What came back from sending a statement, and how long it took — `CodeQuery.Execution.SqlOutcome`. */
class SqlOutcome {
	/** Rows fetched, for a query; null for a statement that answers with a count. */
	public final Rows:Null<Int>;

	/** Rows changed, for a statement; null for a query. */
	public final Affected:Null<Int>;

	public final DurationMs:Float;

	/** What went wrong, where something did; the statement is logged either way. */
	public final Error:Null<String>;

	public function new(?rows:Int, ?affected:Int, durationMs:Float, ?error:String) {
		this.Rows = rows;
		this.Affected = affected;
		this.DurationMs = durationMs;
		this.Error = error;
	}

	/** `12 rows fetched`, `1 row changed`, `failed: …`, or nothing for a statement that answers with neither. */
	public function toString():String {
		if (Error != null) {
			return 'failed: $Error';
		}
		if (Rows != null) {
			return '$Rows row${Rows == 1 ? "" : "s"} fetched';
		}
		if (Affected != null) {
			return '$Affected row${Affected == 1 ? "" : "s"} changed';
		}
		return "";
	}
}
