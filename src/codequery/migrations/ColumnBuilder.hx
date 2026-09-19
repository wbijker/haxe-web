package codequery.migrations;

/** The builder for a type with no configuration of its own — an `Int`, a `Bool`, a `Guid`. */
class ColumnBuilder<TEntity, TProperty> extends ColumnBuilderBase<TEntity, TProperty, ColumnBuilder<TEntity, TProperty>> {
	public function new(table:EntityTableBuilder<TEntity>, definition:DatabaseTableDefinition, columnName:String,
			type:DatabaseColumnType, nullable:Bool, isGuid:Bool = false) {
		super(table, definition, columnName, type, nullable, isGuid);
	}
}
