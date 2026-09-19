package codequery.sqlexpressions;

/**
	A SELECT statement as data.

	Projection and grouping are still to come; what a select can say — its sources, its WHERE,
	whether it is distinct, its ordering and how many rows it wants — is here.
**/
class SelectExpression {
	public final Source:ISqlSource;

	public final Joins:Array<JoinSqlExpression> = [];

	/** What the statement selects; null selects the rows themselves. */
	public var Selection:Null<ISqlExpression>;

	public var Where:Null<ISqlExpression>;

	public var IsDistinct:Bool = false;

	/** `DISTINCT ON (…)` — one row per distinct key, the first in the query's own ordering. */
	public final DistinctOn:Array<ISqlExpression> = [];

	public final OrderBy:Array<OrderByExpression> = [];

	public var Limit:Null<Int>;
	public var Offset:Null<Int>;
	public var WithTies:Bool = false;
	public var Percent:Bool = false;

	public function new(source:ISqlSource) {
		this.Source = source;
	}

	/** Every source the statement names, in the order a lambda's parameters bind to them. */
	public function AllSources():Array<ISqlSource> {
		final sources = [Source];
		for (join in Joins) {
			sources.push(join.Source);
		}
		return sources;
	}

	/** A copy, so a clause answers with a statement of its own and leaves this one alone. */
	public function Fork():SelectExpression {
		final copy = new SelectExpression(Source);
		for (join in Joins) {
			copy.Joins.push(join);
		}
		copy.Selection = Selection;
		copy.Where = Where;
		copy.IsDistinct = IsDistinct;
		for (key in DistinctOn) {
			copy.DistinctOn.push(key);
		}
		for (term in OrderBy) {
			copy.OrderBy.push(term);
		}
		copy.Limit = Limit;
		copy.Offset = Offset;
		copy.WithTies = WithTies;
		copy.Percent = Percent;
		return copy;
	}
}
