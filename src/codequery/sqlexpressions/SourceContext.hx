package codequery.sqlexpressions;

/** Hands out the aliases a statement's sources are known by: t0, t1, t2 … */
class SourceContext {
	var aliasCounter:Int = 0;

	public final Sources:Array<ISqlSource> = [];

	public function new() {}

	public function GenerateAlias():String {
		return "t" + aliasCounter++;
	}

	public function AddTableSource(table:QualifiedTableName):TableSqlSource {
		final source = new TableSqlSource(table, GenerateAlias());
		Sources.push(source);
		return source;
	}

	/** A copy, so that adding a clause never disturbs the query it was asked of. */
	public function Fork():SourceContext {
		final copy = new SourceContext();
		copy.aliasCounter = aliasCounter;
		for (source in Sources) {
			copy.Sources.push(source);
		}
		return copy;
	}
}
