package codequery.queries;

/**
	What a row has to be before it is sent: a value that will not fit the column it is going into
	is refused here, by name, rather than by the database in whatever terms that database uses.

	The database would catch most of this — but not all of it, and not usefully: a message about
	`character varying(40)` says nothing about which of twenty thousand rows was too long, or which
	member it came from. Checking here can say both.
**/
class InsertValidation {
	/** Checks every row against the rules, throwing on the first value that will not fit. */
	public static function Check(rows:Array<Array<Dynamic>>, rules:Array<ColumnRule>, table:QualifiedTableName,
			entity:String):Void {
		final checked = rules.filter(rule -> rule.Limits());
		if (checked.length == 0) {
			return;
		}
		for (index => row in rows) {
			if (row == null) {
				continue;
			}
			for (at => rule in rules) {
				if (rule.Limits()) {
					CheckValue(rule, row[at], table, entity, index, rows.length);
				}
			}
		}
	}

	static function CheckValue(rule:ColumnRule, value:Dynamic, table:QualifiedTableName, entity:String, index:Int,
			total:Int):Void {
		if (value == null) {
			if (!rule.Nullable) {
				throw Refused(rule, table, entity, index, total, null,
					"the column does not take null. Give the member a value, make it nullable so the column is "
					+ "too, or give the column a default for the database to fall back on.");
			}
			return;
		}

		switch rule.Type {
			case SqlVarChar(max) if (Std.isOfType(value, String)):
				final text:String = value;
				if (text.length > max) {
					throw Refused(rule, table, entity, index, total, value,
						'it is ${text.length} characters and the column holds $max. A database that refuses this '
						+ 'says so about the column; one that does not keeps the first $max characters and loses the rest.');
				}
			case SqlDecimal(precision, scale) if (Std.isOfType(value, Float)):
				// What DECIMAL(p, s) can hold left of the point is p − s digits; the rest is the
				// fraction, which the database rounds rather than refuses.
				final number:Float = value;
				final whole = Math.ffloor(Math.abs(number));
				final room = precision - scale;
				if (room <= 0 || whole >= Math.pow(10, room)) {
					throw Refused(rule, table, entity, index, total, value,
						'the column is DECIMAL($precision, $scale), which holds $room digit${room == 1 ? "" : "s"} before the point.');
				}
			case _:
		}
	}

	/**
		What was refused, said in the four things needed to act on it: the table and column it was
		going into, the value, and why it would not fit — with the member and the row it came from.
	**/
	static function Refused(rule:ColumnRule, table:QualifiedTableName, entity:String, index:Int, total:Int,
			value:Dynamic, reason:String):InsertRefused {
		final qualified = table.toString();
		final row = total == 1 ? "" : ' (row $index of $total)';
		return new InsertRefused('$entity.${rule.Member}$row does not fit $qualified.${rule.Column}.'
			+ '\n  table     $qualified'
			+ '\n  column    ${rule.Column} (${Described(rule)})'
			+ '\n  property  $entity.${rule.Member}'
			+ '\n  value     ${Display(value)}'
			+ '\n  reason    $reason');
	}

	/** The column as its type and whatever bounds it carries — VarChar(10), Decimal(5, 2). */
	static function Described(rule:ColumnRule):String {
		final type = switch rule.Type {
			case SqlVarChar(max): 'VarChar($max)';
			case SqlDecimal(precision, scale): 'Decimal($precision, $scale)';
			case SqlInt: "Int";
			case SqlBigInt: "BigInt";
			case SqlFloat: "Float";
			case SqlBool: "Bool";
			case SqlText: "Text";
			case SqlDate: "Date";
			case SqlTimestamp: "DateTime";
			case SqlSmallInt: "SmallInt";
			case SqlReal: "Real";
			case SqlNamed(name): name;
			case SqlChar(length): 'Char($length)';
			case SqlGuid: "Guid";
			case SqlJson: "Json";
			case SqlBinary: "Binary";
			case SqlTime: "Time";
			case SqlUnknown: "Unknown";
		}
		return rule.Nullable ? type : type + ", NOT NULL";
	}

	/** The value as it can be read: quoted where it is text, cut where it is long, said plainly where absent. */
	static function Display(value:Dynamic):String {
		if (value == null) {
			return "null";
		}
		if (Std.isOfType(value, String)) {
			final text:String = value;
			return text.length > 40 ? '\'${text.substr(0, 40)}…\' (${text.length} characters)' : '\'$text\'';
		}
		return Std.string(value);
	}
}
