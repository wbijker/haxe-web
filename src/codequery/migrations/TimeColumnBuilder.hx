package codequery.migrations;

import codequery.migrations.EntityTableBuilder;

/** A time-of-day column: `Time`. The C# builder of the same name; what it offers lives on `ColumnBuilder`. */
class TimeColumnBuilder<TEntity, TProperty> extends ColumnBuilder<TEntity, TProperty> {
	public function new(table:EntityTableBuilder<TEntity>, name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String) {
		super(table, name, type, nullable, false, null, entity);
	}
}
