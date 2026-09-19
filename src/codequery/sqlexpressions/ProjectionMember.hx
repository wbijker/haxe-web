package codequery.sqlexpressions;

/**
	One member of a projection: what it selects, the name it comes back under, and where in the
	answer it belongs.

	The last of those is the `Path`. A projection is a tree — `{data: {col: t.id}}`, `{unit: u}` —
	and a result set is flat, so the tree is flattened into columns named along the way: `data_col`,
	`unit_id`. The path is that walk kept as what it is rather than guessed back out of the name,
	which is what lets a query built over this one find the column a member means.
**/
class ProjectionMember {
	/**
		What joins the steps of a path into the name of the column carrying them. Inlined, since a
		schema declaring a view reaches this while static initialisers are still running.
	**/
	public static inline final Separator = "_";

	/** Empty where the projection is one expression that names nothing — `a -> a.name`. */
	public final Name:String;

	/** Where the value belongs in the answer: the members to walk, outermost first. */
	public final Path:Array<String>;

	public final Expression:ISqlExpression;

	/** A member assigned straight to `name`, or along `path` and named for the whole of it. */
	public function new(name:String, expression:ISqlExpression, ?path:Array<String>) {
		this.Name = name;
		this.Path = path != null ? path : (name == "" ? [] : [name]);
		this.Expression = expression;
	}

	/** A member assigned along `path`, and named for the whole of it. */
	public static function Along(path:Array<String>, expression:ISqlExpression):ProjectionMember {
		return new ProjectionMember(path.join(Separator), expression, path);
	}

	/** The same member, one step deeper: assigned to `member`'s object. */
	public function Under(member:String):ProjectionMember {
		return Along([member].concat(Path), Expression);
	}
}
