package codequery.sqlexpressions;

/**
	A SELECT statement as data.

	Joins, projection and grouping are still to come; what a single-table select can say — its
	source, its WHERE, whether it is distinct, its ordering and how many rows it wants — is here.
**/
class SelectExpression {
	public final Source:ISqlSource;

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

	/** A copy, so a clause answers with a statement of its own and leaves this one alone. */
	public function Fork():SelectExpression {
		final copy = new SelectExpression(Source);
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
