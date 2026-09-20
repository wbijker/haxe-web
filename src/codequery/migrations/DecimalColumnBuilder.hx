package codequery.migrations;

import codequery.migrations.EntityTableBuilder;

/** A decimal column: `Precision`. The C# builder of the same name; what it offers lives on `ColumnBuilder`. */
class DecimalColumnBuilder<TEntity, TProperty> extends ColumnBuilder<TEntity, TProperty> {
	public function new(table:EntityTableBuilder<TEntity>, name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String) {
		super(table, name, type, nullable, false, null, entity);
	}
}
