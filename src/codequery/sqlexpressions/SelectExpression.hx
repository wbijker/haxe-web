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

	/** `FOR UPDATE OF …` — which of the statement's sources the lock names; none names them all. */
	public final LockTables:Array<ISqlSource> = [];

	/**
		Marked as a `WITH` member: a statement selecting from this one hoists it into a WITH clause
		and reads it by name, rather than inlining it as a subquery. `AsCte` sets it.
	**/
	public var IsCte:Bool = false;

	/** The name the CTE is given, or null for one made up when it is rendered. */
	public var CteName:Null<String>;

	/** A recursive CTE: its first union member reads the CTE itself, by name. */
	public var IsRecursive:Bool = false;

	/** A line comment above the statement, and one below it — `WithComments`. */
	public var CommentAbove:Null<String>;
	public var CommentBelow:Null<String>;

	public function new(source:ISqlSource) {
		this.Source = source;
	}

	/**
		True when nothing has been added but the clauses that say *which* rows come back rather than
		what they hold — DISTINCT, LIMIT, OFFSET, a lock, a comment. They name no columns, so they can
		move into the statement this one wraps as they are; a WHERE or an ORDER BY cannot.
	**/
	public function IsEmptyApartFromRowRules():Bool {
		return Selection == null
			&& Where == null
			&& Joins.length == 0
			&& OrderBy.length == 0
			&& GroupBy.length == 0
			&& GroupingSets.length == 0
			&& Having == null
			&& Unions.length == 0
			&& DistinctOn.length == 0
			&& Windows.length == 0
			&& With.length == 0;
	}

	/** Whether any of the row rules `IsEmptyApartFromRowRules` leaves aside is set. */
	public function HasRowRules():Bool {
		return IsDistinct
			|| DistinctOn.length > 0
			|| Limit != null
			|| Offset != null
			|| WithTies
			|| Percent
			|| Lock != None
			|| CommentAbove != null
			|| CommentBelow != null;
	}

	/** True when no clause at all has been added. */
	public function IsEmpty():Bool {
		return IsEmptyApartFromRowRules() && !HasRowRules();
	}

	/** `SELECT * FROM table`, and nothing else. */
	public function IsSimpleTableQuery():Bool {
		return Std.isOfType(Source, TableSqlSource) && IsEmpty();
	}

	/** `SELECT * FROM (subquery)`, and nothing else. */
	public function IsSimpleWrapper():Bool {
		return Std.isOfType(Source, QuerySqlSource) && IsEmpty();
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
		for (table in LockTables) {
			copy.LockTables.push(table);
		}
		copy.IsCte = IsCte;
		copy.CteName = CteName;
		copy.IsRecursive = IsRecursive;
		copy.CommentAbove = CommentAbove;
		copy.CommentBelow = CommentBelow;
		return copy;
	}
}
