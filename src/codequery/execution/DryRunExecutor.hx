package codequery.execution;

/**
	An executor that runs nothing: every query answers with no rows and every statement with no
	rows changed. For a target with no database client, so that a configuration built there still
	sends its statements through — to a logger, say — the way it would anywhere else.
**/
class DryRunExecutor implements IDatabaseExecutor {
	public function new() {}

	public function Query(statement:Statement):Array<Map<String, Dynamic>> {
		return [];
	}

	public function NonQuery(statement:Statement):Int {
		return 0;
	}
}
