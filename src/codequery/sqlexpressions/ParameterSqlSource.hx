package codequery.sqlexpressions;

/**
	The source a lambda parameter stands for, by position.

	A generated column has to name the source it belongs to, but a static cannot know which source
	that is: the same table joined to itself is two sources, and only the statement knows their
	aliases. What a static *can* know is the position of the lambda parameter the column was reached
	through — `(a, b) -> a.id == b.deliveryId` binds `a` to 0 and `b` to 1 while compiling — so that
	is what a generated column carries. The alias is looked up against the statement's own sources
	when it is rendered.
**/
class ParameterSqlSource implements ISqlSource {
	static final cached:Array<ParameterSqlSource> = [];

	public final Index:Int;

	/** A placeholder; the statement's source at `Index` is what a column really renders as. */
	public var Alias(default, null):String;

	function new(index:Int) {
		this.Index = index;
		this.Alias = "$" + index;
	}

	/** The source for parameter `index`, one instance per position. */
	public static function At(index:Int):ParameterSqlSource {
		while (cached.length <= index) {
			cached.push(new ParameterSqlSource(cached.length));
		}
		return cached[index];
	}
}
