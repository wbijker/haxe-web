package codequery.sqlexpressions;

import codequery.DateFormat;

/**
	A date formatted by named parts (see `IDateFormat`). The parts are dialect-neutral; each driver
	renders them with its own function and its own tokens — `to_char`, `FORMAT`, `DATE_FORMAT`,
	`strftime` — and refuses the parts it cannot express.
**/
class DateFormatSqlExpression implements ISqlExpression {
	/** The date being formatted. */
	public final Value:ISqlExpression;

	/** The format, in the order it was written. */
	public final Parts:Array<DateFormatPart>;

	public function new(value:ISqlExpression, parts:Array<DateFormatPart>) {
		this.Value = value;
		this.Parts = parts;
	}
}
