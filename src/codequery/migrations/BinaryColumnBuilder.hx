package codequery.migrations;

import codequery.migrations.EntityTableBuilder;

/** A bytes column: `MaxLength`, `Fixed`, `Blob`. The C# builder of the same name; what it offers lives on `ColumnBuilder`. */
class BinaryColumnBuilder<TEntity> extends ColumnBuilder<TEntity, haxe.io.Bytes> {
	public function new(table:EntityTableBuilder<TEntity>, name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String) {
		super(table, name, type, nullable, false, null, entity);
	}
}
