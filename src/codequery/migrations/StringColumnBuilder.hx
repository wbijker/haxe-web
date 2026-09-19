package codequery.migrations;

/** A text column: `MaxLength`, `Fixed`, `Text`, `Unicode`. */
class StringColumnBuilder<TEntity> extends ColumnBuilderBase<TEntity, String, StringColumnBuilder<TEntity>> {
	public function new(table:EntityTableBuilder<TEntity>, definition:DatabaseTableDefinition, columnName:String,
			type:DatabaseColumnType, nullable:Bool) {
		super(table, definition, columnName, type, nullable);
	}
}
