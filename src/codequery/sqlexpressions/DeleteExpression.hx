package codequery.sqlexpressions;

/** A DELETE statement as data. */
class DeleteExpression implements ISqlStatement {
	public final Target:ISqlSource;

	/** The sources a `DELETE … USING` is correlated against. */
	public final FromSources:Array<ISqlSource> = [];

	public var Where:Null<ISqlExpression>;

	public final Returning:Array<ISqlExpression> = [];

	public function new(target:ISqlSource) {
		this.Target = target;
	}

	public function AllSources():Array<ISqlSource> {
		return [Target].concat(FromSources);
	}

	public function Fork():DeleteExpression {
		final copy = new DeleteExpression(Target);
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
