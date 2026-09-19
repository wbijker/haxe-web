package codequery;

import codequery.sqlexpressions.WindowBound;

/**
	An aggregate over 8 rows under construction — `Aggregate`, with its lambdas over every row the
	query has. Generated from `Aggregate`; see it for what each does.
**/
abstract Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, T>(Dynamic) {
	// A comparison or a sum written against an aggregate inside HAVING types as one against its
	// value; nothing here runs, the lambda is read while compiling.
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

	/** The value the aggregate stands for. Never actually called. */
	@:to function toValue():T {
		return cast this;
	}

	/** Reads it over a window the query named. */
	public function over(window:INamedWindow):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, T> {
		return cast this;
	}

	/**
		Reads it over a window written out here, rather than one the query named:
		`.overRows(w -> w.PartitionBy(r -> r.unitId).OrderBy(r -> r.checkIn))`.
	**/
	public function overRows(spec:WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8>->WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8>):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, T> {
		return cast this;
	}

	/** `FILTER (WHERE …)` — counts only the rows the condition holds for. */
	public function filter(predicate:T1->T2->T3->T4->T5->T6->T7->T8->Bool):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, T> {
		return cast this;
	}

	/** `DISTINCT` inside the aggregate — over distinct values rather than every one. */
	public function distinct():Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, T> {
		return cast this;
	}
}
