package codequery;

import codequery.sqlexpressions.WindowBound;

/**
	An aggregate over 6 rows under construction — `Aggregate`, with its lambdas over every row the
	query has. Generated from `Aggregate`; see it for what each does.
**/
abstract Aggregate6<T1, T2, T3, T4, T5, T6, T>(Dynamic) {
	/** The value the aggregate stands for. Never actually called. */
	@:to function toValue():T {
		return cast this;
	}

	/** Reads it over a window the query named. */
	public function over(window:INamedWindow):Aggregate6<T1, T2, T3, T4, T5, T6, T> {
		return cast this;
	}

	/**
		Reads it over a window written out here, rather than one the query named:
		`.overRows(w -> w.PartitionBy(r -> r.unitId).OrderBy(r -> r.checkIn))`.
	**/
	public function overRows(spec:WindowSpec6<T1, T2, T3, T4, T5, T6>->WindowSpec6<T1, T2, T3, T4, T5, T6>):Aggregate6<T1, T2, T3, T4, T5, T6, T> {
		return cast this;
	}

	/** `FILTER (WHERE …)` — counts only the rows the condition holds for. */
	public function filter(predicate:T1->T2->T3->T4->T5->T6->Bool):Aggregate6<T1, T2, T3, T4, T5, T6, T> {
		return cast this;
	}

	/** `DISTINCT` inside the aggregate — over distinct values rather than every one. */
	public function distinct():Aggregate6<T1, T2, T3, T4, T5, T6, T> {
		return cast this;
	}
}
