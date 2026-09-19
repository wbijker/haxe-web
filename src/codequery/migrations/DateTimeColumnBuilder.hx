package codequery.migrations;

/** A date/time column: `Date`, `DateTime`, `Timestamp`, `Time`. */
class DateTimeColumnBuilder<TEntity, TProperty> extends ColumnBuilderBase<TEntity, TProperty, DateTimeColumnBuilder<TEntity, TProperty>> {
	public function new(table:EntityTableBuilder<TEntity>, definition:DatabaseTableDefinition, columnName:String,
			type:DatabaseColumnType, nullable:Bool) {
		super(table, definition, columnName, type, nullable);
	}
}
