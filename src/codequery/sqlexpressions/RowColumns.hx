package codequery.sqlexpressions;

/**
	What a lambda's parameter is when the query runs: the columns of the row it stands for, each an
	expression naming that column.

	`ColumnsBuilder` generates a subclass per entity — `BookingColumns`, with one member per column
	and an object flattened into the row as a `RowColumns` of its own (`price.zar`) — and the
	callback a clause was compiled to is handed one for each row the query is over. The source is
	the position of the parameter, as it always was; the statement settles which alias that is when
	it renders.
**/
class RowColumns {
	/** The source the columns belong to: the lambda parameter's position, settled when rendering. */
	public final Source:ISqlSource;

	/** The column-name prefix of an object flattened into its owner's row — `price_` for `price.zar`. */
	public final Prefix:String;

	public function new(source:ISqlSource, prefix:String = "") {
		this.Source = source;
		this.Prefix = prefix;
	}

	/**
		The members in the order the entity declares them: the field, the column-name segment it
		maps to, and what it holds — a `ColumnSqlExpression`, or the `RowColumns` of an object
		flattened into this row. Generated per entity; this is the base's empty answer.
	**/
	public function Members():Array<RowMember> {
		return [];
	}
}

typedef RowMember = {
	/** The field's name, which is how a lambda reaches it. */
	final name:String;

	/** The segment the field contributes to its column's name — `@columnName`, else the field's. */
	final column:String;

	/** A `ColumnSqlExpression`, or a nested `RowColumns`. */
	final value:Dynamic;
};
