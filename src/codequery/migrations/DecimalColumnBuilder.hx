package codequery.migrations;

/** A decimal column: `Precision`. */
class DecimalColumnBuilder<TEntity, TProperty> extends ColumnBuilderBase<TEntity, TProperty, DecimalColumnBuilder<TEntity, TProperty>> {
	public function new(table:EntityTableBuilder<TEntity>, definition:DatabaseTableDefinition, columnName:String,
			type:DatabaseColumnType, nullable:Bool) {
		super(table, definition, columnName, type, nullable);
	}
}
