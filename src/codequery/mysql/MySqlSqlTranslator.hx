package codequery.mysql;

import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.DeleteExpression;
import codequery.sqlexpressions.MergeExpression;
import codequery.sqlexpressions.SchemaChangeExpression.CreateTableExpression;
import codequery.sqlexpressions.UpdateExpression;
import codequery.sqlexpressions.InsertExpression;
import codequery.sqlexpressions.IntervalSqlExpression;
import codequery.sqlexpressions.IsDistinctFromSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.JoinType;
import codequery.sqlexpressions.SqlType;

/**
	The dialect as MySQL and MariaDB read it: `CodeQuery.MySql.MySqlSqlTranslator`.

	What differs from the base is what MySQL lacks or spells its own way — no `IS DISTINCT FROM`
	but a null-safe `<=>`, no `RETURNING`, no `ON CONFLICT` but `ON DUPLICATE KEY UPDATE`, no
	identity clause but `AUTO_INCREMENT`, an `INTERVAL` that is a keyword pair rather than a value,
	and its own names for a handful of types. Values are sent beside the statement as `?`, which is
	how every MySQL client binds them.
**/
class MySqlSqlTranslator extends SqlTranslator {
	public function new() {
		super();
	}

	override public function Placeholder(ordinal:Int):String {
		return "?";
	}

	/** MySQL has no `IS DISTINCT FROM`; it has the null-safe equality `<=>`, and this is its negation. */
	override public function OnIsDistinctFrom(e:IsDistinctFromSqlExpression):String {
		final same = '${RenderExpression(e.Left)} <=> ${RenderExpression(e.Right)}';
		return e.Negate ? '($same)' : '(NOT ($same))';
	}

	/**
		MySQL writes a span as `INTERVAL 3 DAY` — a keyword pair rather than a value, so it is only
		a span of one whole unit and only in date arithmetic. A span that is not one whole unit is
		said in microseconds, the one unit that can always say it.
	**/
	override public function OnInterval(e:IntervalSqlExpression):String {
		final whole = e.WholeUnits;
		if (whole != null) {
			return 'INTERVAL ${whole.count} ${Std.string(whole.part).toUpperCase()}';
		}
		return 'INTERVAL ${Std.int(e.Milliseconds * 1000)} MICROSECOND';
	}

	/** MySQL has no FULL OUTER JOIN; the nearest it says is a LEFT JOIN, which is what the C# driver renders. */
	override function JoinKeyword(type:JoinType):String {
		return switch type {
			case Outer: "LEFT JOIN";
			case _: super.JoinKeyword(type);
		}
	}

	/** MySQL has no `OVERRIDING … VALUE`: a row that carries its own key simply keeps it. */
	override function Overriding(mode:codequery.sqlexpressions.IdentityOverride):String {
		return "";
	}

	/**
		MySQL has no `RETURNING`: a generated key is read back with `LAST_INSERT_ID()` by whoever ran
		the insert, so a request for returned columns is left out of the statement.
	**/
	override function Returning(returning:Array<ISqlExpression>):String {
		return "";
	}

	/** …and an UPDATE or DELETE has no way of reading its rows back at all, so asking is refused. */
	override function UpdateSql(update:UpdateExpression):String {
		if (update.Returning.length > 0) {
			throw "MySQL does not support RETURNING/OUTPUT on UPDATE or DELETE.";
		}
		return super.UpdateSql(update);
	}

	override function DeleteSql(delete:DeleteExpression):String {
		if (delete.Returning.length > 0) {
			throw "MySQL does not support RETURNING/OUTPUT on UPDATE or DELETE.";
		}
		return super.DeleteSql(delete);
	}

	/** MySQL has no MERGE statement; an upsert is `INSERT … ON DUPLICATE KEY UPDATE`. */
	override function MergeSql(merge:MergeExpression):String {
		throw "MySQL does not support MERGE; use INSERT ... ON DUPLICATE KEY UPDATE.";
	}

	/**
		An upsert is `INSERT … ON DUPLICATE KEY UPDATE`, with no say over which key conflicts; doing
		nothing is a no-op self-assignment, and the row that was offered is read with `VALUES(col)`
		rather than `EXCLUDED.col`.
	**/
	override function Conflict(insert:InsertExpression):String {
		if (insert.OnConflict == null) {
			return "";
		}
		return switch insert.OnConflict {
			case DoNothing:
				final first = insert.Columns[0].ColumnName;
				' ON DUPLICATE KEY UPDATE $first = $first';
			case DoUpdate:
				final set = insert.ConflictUpdates.length > 0
					? insert.ConflictUpdates
						.map(a -> '${a.Column.ColumnName} = ${RenderExpression(a.Value)}')
						.join(", ")
					: ConflictUpdateColumns(insert).map(c -> '$c = VALUES($c)').join(", ");
				' ON DUPLICATE KEY UPDATE $set';
		}
	}

	// ---- DDL ---------------------------------------------------------------------------------------

	/** `AUTO_INCREMENT`, after the nullability: `id INT NOT NULL AUTO_INCREMENT`. */
	override public function IdentityClause(column:ColumnDefinition):Null<String> {
		return "AUTO_INCREMENT";
	}

	override function get_IdentityAfterNullability():Bool {
		return true;
	}

	/** MySQL has TEMPORARY tables and no UNLOGGED ones. */
	override public function TableModifierKeyword(e:CreateTableExpression):String {
		if (e.Unlogged) {
			throw "MySQL does not support UNLOGGED tables.";
		}
		return e.Temporary ? "TEMPORARY " : "";
	}

	/** MySQL has no SERIAL type; a serial column is an integer that auto-increments. */
	override public function SerialTypeName(column:ColumnDefinition):Null<String> {
		return null;
	}

	/**
		`ALTER TABLE … AUTO_INCREMENT = n`. MySQL's counter is set to the next value it will hand out
		rather than to the last one used, so it is the key after the highest that goes in here.
	**/
	override public function BuildResyncIdentitySql(tableName:String, ?schema:String, columnName:String, highestKey:Int):String {
		final qualified = schema == null ? tableName : '$schema.$tableName';
		return 'ALTER TABLE $qualified AUTO_INCREMENT = ${highestKey + 1}';
	}

	/** A TEXT column cannot be a key in MySQL without a prefix length; the names are short, so VARCHAR. */
	override public function MigrationHistoryDdl(table:String):String {
		return 'CREATE TABLE IF NOT EXISTS $table (name VARCHAR(255) PRIMARY KEY)';
	}

	override public function RenderType(type:SqlType):String {
		return switch type {
			case SqlInt: "INT";
			case SqlFloat: "DOUBLE";
			case SqlBool: "TINYINT(1)";
			// MySQL's TIMESTAMP is a narrow, timezone-shifted type; DATETIME is the plain one.
			case SqlTimestamp: "DATETIME";
			case SqlGuid: "CHAR(36)";
			case SqlBinary: "BLOB";
			case _: super.RenderType(type);
		}
	}

	/** In a CAST MySQL names integers SIGNED, booleans UNSIGNED, and text CHAR. */
	override public function RenderCastType(type:SqlType):String {
		return switch type {
			case SqlInt | SqlBigInt | SqlSmallInt: "SIGNED";
			case SqlBool: "UNSIGNED";
			case SqlText | SqlVarChar(_): "CHAR";
			case SqlFloat: "DOUBLE";
			case SqlReal: "FLOAT";
			case SqlTimestamp: "DATETIME";
			case _: super.RenderCastType(type);
		}
	}
}
