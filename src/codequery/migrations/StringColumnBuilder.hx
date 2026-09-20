package codequery.migrations;

import codequery.migrations.EntityTableBuilder;

/** A text column: `MaxLength`, `Fixed`, `Text`, `Unicode`, `Json`, `Xml`. The C# builder of the same name; what it offers lives on `ColumnBuilder`. */
class StringColumnBuilder<TEntity> extends ColumnBuilder<TEntity, String> {
	public function new(table:EntityTableBuilder<TEntity>, name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String) {
		super(table, name, type, nullable, false, null, entity);
	}
}
