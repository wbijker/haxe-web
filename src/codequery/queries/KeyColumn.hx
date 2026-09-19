package codequery.queries;

/** An entity's primary key, as the runtime needs to know it. */
class KeyColumn {
	public final Member:String;
	public final Column:String;

	/** The member's type, by name, for a message about it. */
	public final TypeName:String;

	/** Whether a sequence could count towards it — an integer, that is. */
	public final Numeric:Bool;

	/** Whether it is one of several — a composite key, which a single-column read-back cannot correlate. */
	public final Composite:Bool;

	public function new(member:String, column:String, typeName:String, numeric:Bool, composite:Bool = false) {
		this.Member = member;
		this.Column = column;
		this.TypeName = typeName;
		this.Numeric = numeric;
		this.Composite = composite;
	}
}
