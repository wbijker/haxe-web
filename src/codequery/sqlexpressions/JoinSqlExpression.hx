package codequery.sqlexpressions;

/** A joined source and what it is joined on. A cross join has no condition. */
class JoinSqlExpression {
	public final Type:JoinType;
	public final Source:ISqlSource;
	public final On:Null<ISqlExpression>;

	public function new(type:JoinType, source:ISqlSource, on:Null<ISqlExpression>) {
		this.Type = type;
		this.Source = source;
		this.On = on;
	}
}
