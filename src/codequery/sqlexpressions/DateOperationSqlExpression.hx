package codequery.sqlexpressions;

import codequery.DateTimePart;

/**
	A date operation named in the abstract — truncate to a month, count days between two dates,
	read the quarter — for a driver to write in its own dialect. There is no shared spelling to fall
	back on: PostgreSQL truncates with `date_trunc`, SQL Server counts back from an epoch with
	`DATEADD/DATEDIFF`, MySQL reformats the date, SQLite says `start of month`. The part a dialect
	cannot do it says so, rather than approximating.
**/
class DateOperationSqlExpression implements ISqlExpression {
	public final Operation:DateOperation;

	/** The unit the operation works in. Ignored by the operations that imply their own. */
	public final Part:DateTimePart;

	/** The date operated on — the *start* date for a difference. */
	public final Value:ISqlExpression;

	/** The end date, for a difference; null otherwise. */
	public final Other:Null<ISqlExpression>;

	public function new(operation:DateOperation, part:DateTimePart, value:ISqlExpression, ?other:ISqlExpression) {
		this.Operation = operation;
		this.Part = part;
		this.Value = value;
		this.Other = other;
	}
}
