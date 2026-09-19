package codequery;

import codequery.sqlexpressions.WindowBound;

/**
	An aggregate under construction, inside a `SelectAggregation`.

	Nothing here runs: the projection it appears in is read while compiling and becomes an
	`AggregateSqlExpression`. It is here so the projection type-checks, and so an editor can see
	what an aggregate offers.

	Each of these answers with an aggregate again, so they chain in any order, and one converts to
	the value it stands for wherever that value is wanted.
**/
abstract Aggregate<TRow, T>(Dynamic) {
	/** The value the aggregate stands for. Never actually called. */
	@:to function toValue():T {
		return cast this;
	}

	/** Reads it over a window the query named. */
	public function over(window:INamedWindow):Aggregate<TRow, T> {
		return cast this;
	}

	/**
		Reads it over a window written out here, rather than one the query named:
		`.overRows(w -> w.PartitionBy(r -> r.unitId).OrderBy(r -> r.checkIn))`.
	**/
	public function overRows(spec:WindowSpec<TRow>->WindowSpec<TRow>):Aggregate<TRow, T> {
		return cast this;
	}

	/** `FILTER (WHERE …)` — counts only the rows the condition holds for. */
	public function filter(predicate:TRow->Bool):Aggregate<TRow, T> {
		return cast this;
	}


	// Compared and combined as the value it stands for, which is what a HAVING does with it:
	// `a.count() > 5`, `a.sum(r -> r.total) * 2 > 100`. Typed only; nothing here runs.
	@:op(A == B) function eq(other:T):Bool return false;
	@:op(A != B) function ne(other:T):Bool return false;
	@:op(A < B) function lt(other:T):Bool return false;
	@:op(A <= B) function le(other:T):Bool return false;
	@:op(A > B) function gt(other:T):Bool return false;
	@:op(A >= B) function ge(other:T):Bool return false;
	@:op(A + B) function add(other:T):T return other;
	@:op(A - B) function sub(other:T):T return other;
	@:op(A * B) function mul(other:T):T return other;
	@:op(A / B) function div(other:T):T return other;

	/** `DISTINCT` inside the aggregate — over distinct values rather than every one. */
	public function distinct():Aggregate<TRow, T> {
		return cast this;
	}
}
