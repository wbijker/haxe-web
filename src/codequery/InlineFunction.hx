package codequery;

/**
	A piece of a query written as an ordinary Haxe function, so it can be named, given arguments and
	reused:

	```haxe
	static function Discounted(p:Product, percentOff:Int):InlineFunction<Float> {
		final remaining = 100 - percentOff;
		return InlineFunction.create(() -> p.priceCents * remaining / 100);
	}

	.Select(p -> {cheap: Discounted(p, 10)})
	```

	Unlike a SQL function, nothing of this reaches the database: the call is expanded while the query
	is being compiled, and what the function hands back — the expression inside
	`InlineFunction.create` — is put in place of the call. From there the query is read exactly as
	if that expression had been written out by hand, so the SQL is the same either way.

	The row is an ordinary parameter. While the query is being built there is no row yet, so an
	argument that reads the row is carried into the expression as itself, and every mention of it
	inside `create(() -> …)` is that expression — which is why it has to be a lambda: it is read,
	not run. Anything the function computes *outside* that lambda is ordinary Haxe, run when the
	query is built, and it reaches the SQL as the value it produced — bound beside the statement,
	as a variable's value always is.

	`T` is the value the function yields, so that a call can stand wherever that value is expected:
	an `InlineFunction<Bool>` is a predicate. Where Haxe does not apply the conversion — the operand
	of an operator — `.value` names it.
**/
abstract InlineFunction<T>(Void->T) {
	inline function new(body:Void->T) {
		this = body;
	}

	/**
		The expression this function stands for. It is a lambda so that it is read rather than run —
		the row it reads does not exist yet when the function is called.
	**/
	public static function create<T>(body:Void->T):InlineFunction<T> {
		return new InlineFunction(body);
	}

	/**
		The value this function stands for. Never executed: inside a query lambda it is a node in the
		tree, and the converter reads it as the function's own expression. Outside one it is not a
		value, and says so.
	**/
	public var value(get, never):T;

	function get_value():T {
		throw NotAValue;
	}

	/** Lets the function stand where its value is expected. Never executed, for the same reason. */
	@:to function toValue():T {
		throw NotAValue;
	}

	static inline final NotAValue = "An inline function is part of a query expression and cannot be evaluated in Haxe; "
		+ "use it inside a query lambda.";
}
