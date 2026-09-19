package codequery.migrations;

/** A binary column: `MaxLength`, `Fixed`, `Blob`. */
class BinaryColumnBuilder<TEntity> extends ColumnBuilderBase<TEntity, haxe.io.Bytes, BinaryColumnBuilder<TEntity>> {
	public function new(table:EntityTableBuilder<TEntity>, definition:DatabaseTableDefinition, columnName:String,
			type:DatabaseColumnType, nullable:Bool) {
		super(table, definition, columnName, type, nullable);
	}
}
