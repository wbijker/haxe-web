package codequery;

/**
	An aggregate over 3 rows under construction, inside a `SelectAggregation` — `Aggregate`, for a
	query that has joined. Nothing here runs: the projection it appears in is read while compiling.
**/
abstract Aggregate3<T1, T2, T3, T>(Dynamic) {
	/** The value the aggregate stands for. Never actually called. */
	@:to function toValue():T {
		return cast this;
	}

	/** Reads it over a window the query named. */
	public function over(window:INamedWindow):Aggregate3<T1, T2, T3, T> {
		return cast this;
	}

	/** `FILTER (WHERE …)` — counts only the rows the condition holds for. */
	public function filter(predicate:(T1, T2, T3)->Bool):Aggregate3<T1, T2, T3, T> {
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
	public function distinct():Aggregate3<T1, T2, T3, T> {
		return cast this;
	}
}
