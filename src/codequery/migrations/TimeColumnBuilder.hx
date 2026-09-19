package codequery.migrations;

/** A time column: `Time`. */
class TimeColumnBuilder<TEntity, TProperty> extends ColumnBuilderBase<TEntity, TProperty, TimeColumnBuilder<TEntity, TProperty>> {
	public function new(table:EntityTableBuilder<TEntity>, definition:DatabaseTableDefinition, columnName:String,
			type:DatabaseColumnType, nullable:Bool) {
		super(table, definition, columnName, type, nullable);
	}
}
