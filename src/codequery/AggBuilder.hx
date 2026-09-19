package codequery;

/**
	A `DbAggregation` under construction: filtered, made distinct, and then — always — given the
	window it reads over, which is what turns it into the value it stands for.

	Nothing here runs either; it is here so the projection type-checks and an editor can complete it.
**/
extern class AggBuilder<T> {
	/** `FILTER (WHERE …)` — counts only the rows the condition holds for. */
	public function filter(condition:Bool):AggBuilder<T>;

	/** `DISTINCT` inside the aggregate — over distinct values rather than every one. */
	public function distinct():AggBuilder<T>;

	/**
		`OVER (…)`, in any of its forms: nothing, for the whole result as one window; a partition key
		and an ordering, either of which may be `null`; a window the query named with `Window(…)`;
		or a specification written out on the spot, which is the form that can say a frame.
	**/
	@:overload(function():T {})
	@:overload(function(partitionBy:Dynamic, orderBy:Dynamic):T {})
	@:overload(function(window:INamedWindow):T {})
	public function over(spec:OverSpec->OverSpec):T;
}
