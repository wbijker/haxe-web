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

	/** The same, as column names — which is what a conflict is judged on. */
	public static function NamesOf(keys:Array<ISqlExpression>):Array<String> {
		return keys.map(key -> {
			final column = Std.downcast(cast key, ColumnSqlExpression);
			if (column == null) {
				throw "A conflict is judged on columns, and this is not one";
			}
			return column.ColumnName;
		});
	}
}
