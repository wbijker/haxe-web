package codequery.sqlexpressions;

/** An UPDATE statement as data. */
class UpdateExpression implements ISqlStatement {
	public final Target:ISqlSource;
	public final Assignments:Array<SetAssignment> = [];

	/** The sources an `UPDATE … FROM` draws its new values from. */
	public final FromSources:Array<ISqlSource> = [];

	public var Where:Null<ISqlExpression>;

	public final Returning:Array<ISqlExpression> = [];

	public function new(target:ISqlSource) {
		this.Target = target;
	}

	/** Every source the statement names, in the order a lambda's parameters bind to them. */
	public function AllSources():Array<ISqlSource> {
		return [Target].concat(FromSources);
	}

	/** A copy, so a clause answers with a statement of its own and leaves this one alone. */
	public function Fork():UpdateExpression {
		final copy = new UpdateExpression(Target);
		for (assignment in Assignments) {
			copy.Assignments.push(assignment);
		}
		for (source in FromSources) {
			copy.FromSources.push(source);
		}
		copy.Where = Where;
		for (returned in Returning) {
			copy.Returning.push(returned);
		}
		return copy;
	}
}
