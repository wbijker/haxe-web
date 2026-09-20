package codequery.migrations;

import codequery.migrations.EntityTableBuilder;

/** A date or time column: `Date`, `DateTime`, `Timestamp`, `Time`. The C# builder of the same name; what it offers lives on `ColumnBuilder`. */
class DateTimeColumnBuilder<TEntity, TProperty> extends ColumnBuilder<TEntity, TProperty> {
	public function new(table:EntityTableBuilder<TEntity>, name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String) {
		super(table, name, type, nullable, false, null, entity);
	}
}
