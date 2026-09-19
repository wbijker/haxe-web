package codequery.sqlexpressions;

/** Hands out the aliases a statement's sources are known by: t0, t1, t2 … */
class SourceContext {
	var aliasCounter:Int = 0;

	public final Sources:Array<ISqlSource> = [];

	public function new() {}

	public function GenerateAlias():String {
		return "t" + aliasCounter++;
	}

	/**
		Registers a source. A table brings its own source — and with it the name its columns are
		qualified by — from the entity's generated columns type, so nothing is aliased here yet;
		`GenerateAlias` is waiting for the first statement that names one table twice.
	**/
	public function Add(source:ISqlSource):Void {
		Sources.push(source);
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
