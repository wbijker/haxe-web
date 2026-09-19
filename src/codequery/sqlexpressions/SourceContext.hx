package codequery.sqlexpressions;

/** Hands out the aliases a statement's sources are known by: t0, t1, t2 … */
class SourceContext {
	var aliasCounter:Int = 0;

	public final Sources:Array<ISqlSource> = [];

	/**
		The expressions a reduced row's members stand for — `Reduce((b, u) -> {total: b.cents + 10, u})`
		— keyed by the path joined into a column name, so that reading `x.total` afterwards finds the
		calculation it was projected from rather than a column called that.
	**/
	public final Projected:Map<String, ISqlExpression> = new Map();

	/**
		How many sources the row a reduce built stands for, or zero when nothing has been reduced.
		Once a query has been reduced, a lambda's first parameter is that row — so parameter 1 is
		the source joined *after* the reduce, not the second source of the join it folded up.
	**/
	public var Reduced(default, null):Int = 0;

	public function new() {}

	/** Records that everything added so far is now carried by one row. */
	public function MarkReduced():Void {
		Reduced = Sources.length;
	}

	/** Records what a reduced row's member was projected from. */
	public function RegisterProjected(name:String, expression:ISqlExpression):Void {
		Projected.set(name, expression);
	}

	/** An expression written over the reduced row, read back onto the sources it stands for. */
	public function Resolve(e:ISqlExpression):ISqlExpression {
		return ProjectionResolver.Resolve(e, Projected, Reduced);
	}

	public function GenerateAlias():String {
		return "t" + aliasCounter++;
	}

	/** Registers a table under an alias of its own, so one table can be named twice. */
	public function AddTableSource(table:QualifiedTableName):TableSqlSource {
		final source = new TableSqlSource(table, GenerateAlias());
		Sources.push(source);
		return source;
	}

	/** Registers a subquery under an alias of its own. */
	public function AddQuerySource(query:SelectExpression, projected:Bool = false):QuerySqlSource {
		final source = new QuerySqlSource(query, GenerateAlias(), projected);
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
		copy.Reduced = Reduced;
		for (name => expression in Projected) {
			copy.Projected.set(name, expression);
		}
		return copy;
	}
}
