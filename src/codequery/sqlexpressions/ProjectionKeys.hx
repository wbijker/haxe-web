package codequery.sqlexpressions;

/** The expressions of a projection, as a plain list — which is what a grouping set is. */
class ProjectionKeys {
	public static function Of(selection:ISqlExpression):Array<ISqlExpression> {
		final projection = Std.downcast(cast selection, ProjectionSqlExpression);
		if (projection != null) {
			return projection.Members.map(member -> member.Expression);
		}
		// A lambda naming one key rather than building a structure.
		return [selection];
	}
}
