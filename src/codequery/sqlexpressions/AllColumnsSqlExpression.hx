package codequery.sqlexpressions;

/** Every column of one source — `t1.*`, which is what projecting a whole row selects. */
class AllColumnsSqlExpression implements ISqlExpression {
	public final Source:ISqlSource;

	public function new(source:ISqlSource) {
		this.Source = source;
	}
}
