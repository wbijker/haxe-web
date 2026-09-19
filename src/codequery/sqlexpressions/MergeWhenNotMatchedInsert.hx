package codequery.sqlexpressions;

/** `WHEN NOT MATCHED THEN INSERT (cols) VALUES (vals)`. */
class MergeWhenNotMatchedInsert extends MergeAction {
	public final Columns:Array<String>;
	public final Values:Array<ISqlExpression>;

	public function new(columns:Array<String>, values:Array<ISqlExpression>, ?condition:ISqlExpression) {
		super(condition);
		this.Columns = columns;
		this.Values = values;
	}
}
