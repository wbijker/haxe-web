package codequery.sqlexpressions;

/**
	A SELECT statement as data.

	Projection and grouping are still to come; what a select can say — its sources, its WHERE,
	whether it is distinct, its ordering and how many rows it wants — is here.
**/
class SelectExpression implements ISqlStatement {
	public final Source:ISqlSource;

	public final Joins:Array<JoinSqlExpression> = [];

	/** What the statement selects; null selects the rows themselves. */
	public var Selection:Null<ISqlExpression>;

	public var Where:Null<ISqlExpression>;

	public final GroupBy:Array<ISqlExpression> = [];

	/** Plain grouping, or one of the two that also group the totals. */
	public var Grouping:GroupingMode = None;

	/** `GROUPING SETS (…)` — the groupings named one by one rather than derived. */
	public final GroupingSets:Array<Array<ISqlExpression>> = [];

	/** The queries named in front of this one, which it and they can select from. */
	public final With:Array<CommonTableExpression> = [];

	/** What the statement locks of the rows it reads. */
	public var Lock:RowLockMode = None;

	public var LockSkipLocked:Bool = false;
	public var LockNoWait:Bool = false;

	/** The statements this one's rows are put together with. */
	public final Unions:Array<UnionSqlExpression> = [];

	public var Having:Null<ISqlExpression>;

	/** Windows defined on this statement, which its aggregates read over by name. */
	public final Windows:Array<NamedWindowSqlSource> = [];

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

	/**
		Every source the statement names, in the order a lambda's parameters bind to them. A window
		is one of them: `Window` hands the projection after it an extra parameter to name it by.
	**/
	public function AllSources():Array<ISqlSource> {
		final sources:Array<ISqlSource> = [Source];
		for (join in Joins) {
			sources.push(join.Source);
		}
		for (window in Windows) {
			sources.push(window);
		}
		return sources;
	}

	/** Whether the statement says nothing beyond its source — `SELECT * FROM <source>`. */
	public var IsEmpty(get, never):Bool;

	function get_IsEmpty():Bool {
		return IsEmptyApartFromRowRules && !IsDistinct && Limit == null && Offset == null;
	}

	/** `SELECT * FROM (<subquery>)` and nothing else, which says no more than the subquery does. */
	public var IsSimpleWrapper(get, never):Bool;

	function get_IsSimpleWrapper():Bool {
		return Std.isOfType(Source, QuerySqlSource) && IsEmpty;
	}

	/** Empty but for DISTINCT, LIMIT or OFFSET — the clauses that can move into a subquery. */
	public var IsEmptyApartFromRowRules(get, never):Bool;

	function get_IsEmptyApartFromRowRules():Bool {
		return Joins.length == 0 && Selection == null && Where == null && GroupBy.length == 0
			&& GroupingSets.length == 0 && With.length == 0 && Lock == None && Unions.length == 0
			&& Having == null && Windows.length == 0 && DistinctOn.length == 0 && OrderBy.length == 0
			&& !WithTies && !Percent;
	}

	/** A copy, so a clause answers with a statement of its own and leaves this one alone. */
	public function Fork():SelectExpression {
		final copy = new SelectExpression(Source);
		for (join in Joins) {
			copy.Joins.push(join);
		}
		copy.Selection = Selection;
		copy.Where = Where;
		for (key in GroupBy) {
			copy.GroupBy.push(key);
		}
		copy.Grouping = Grouping;
		for (set in GroupingSets) {
			copy.GroupingSets.push(set);
		}
		for (cte in With) {
			copy.With.push(cte);
		}
		copy.Lock = Lock;
		copy.LockSkipLocked = LockSkipLocked;
		copy.LockNoWait = LockNoWait;
		for (union in Unions) {
			copy.Unions.push(union);
		}
		copy.Having = Having;
		for (window in Windows) {
			copy.Windows.push(window);
		}
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
