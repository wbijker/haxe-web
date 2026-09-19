package codequery.sqlexpressions;

/**
	The source a lambda parameter stands for, by position — and by how far out.

	A generated column has to name the source it belongs to, but a static cannot know which source
	that is: the same table joined to itself is two sources, and only the statement knows their
	aliases. What a static *can* know is the position of the lambda parameter the column was reached
	through — `(a, b) -> a.id == b.deliveryId` binds `a` to 0 and `b` to 1 while compiling.

	Position alone was not enough for a lateral join. A lateral's inner query is built by its own
	macro calls, which bind their parameters from zero in their own statement — and the outer row is
	also zero, so the two could not be told apart. `Scope` is what tells them apart: zero is the
	statement the column sits in, one is the statement enclosing that, and so on outwards.
**/
class ParameterSqlSource implements ISqlSource {
	/**
		Built on first use, not during static initialisation.

		Haxe runs static initialisers in the order it generated the types, and a schema declaring a
		view reaches this while its own are still running — which would read the map as null.
	**/
	static var cached:Null<Map<String, ParameterSqlSource>>;

	public final Index:Int;

	/** How many statements out the source is: 0 is this one, 1 the one enclosing it. */
	public final Scope:Int;

	/** A placeholder; the statement's source at `Index`, `Scope` out, is what a column renders as. */
	public var Alias(default, null):String;

	function new(index:Int, scope:Int) {
		this.Index = index;
		this.Scope = scope;
		this.Alias = (scope == 0 ? "$" : "^" + scope + "$") + index;
	}

	/** The source for parameter `index`, `scope` statements out — one instance per pairing. */
	public static function At(index:Int, scope:Int = 0):ParameterSqlSource {
		if (cached == null) {
			cached = new Map();
		}
		final key = '$scope:$index';
		final known = cached.get(key);
		if (known != null) {
			return known;
		}
		final made = new ParameterSqlSource(index, scope);
		cached.set(key, made);
		return made;
	}
}
