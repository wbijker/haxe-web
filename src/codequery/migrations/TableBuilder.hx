package codequery.migrations;

import codequery.migrations.DatabaseColumnType;
import codequery.sqlexpressions.ColumnDefinition;

/**
	A table definition built column by column, by name and type — the C# `SchemaBuilder.TableBuilder`.

	`TableBuilder.Create().Table("Users").Int("Id", c -> c.Identity()).String("Name", c -> c.MaxLength(200).NotNull()).Build()`
**/
class TableBuilder {
	var definition:DatabaseTableDefinition = new DatabaseTableDefinition("", []);

	function new() {}

	public static function Create():TableBuilder {
		return new TableBuilder();
	}

	public function Table(name:String, ?schema:String):TableBuilder {
		definition = new DatabaseTableDefinition(name, [], schema);
		return this;
	}

	function Add(name:String, type:DatabaseColumnType, ?configure:TableColumnBuilder->Void):TableBuilder {
		final column = DatabaseColumnDefinition.Of(name, type, true);
		column.OrdinalIndex = definition.Columns.length;
		definition.Columns.push(column);
		if (configure != null) {
			configure(new TableColumnBuilder(column));
		}
		return this;
	}

	public function Int(name:String, ?configure:TableColumnBuilder->Void):TableBuilder {
		return Add(name, DatabaseColumnType.Int, configure);
	}

	public function BigInt(name:String, ?configure:TableColumnBuilder->Void):TableBuilder {
		return Add(name, DatabaseColumnType.BigInt, configure);
	}

	public function String(name:String, ?configure:TableColumnBuilder->Void):TableBuilder {
		return Add(name, DatabaseColumnType.VarChar, configure);
	}

	public function Text(name:String, ?configure:TableColumnBuilder->Void):TableBuilder {
		return Add(name, DatabaseColumnType.Text, configure);
	}

	public function Decimal(name:String, ?configure:TableColumnBuilder->Void):TableBuilder {
		return Add(name, DatabaseColumnType.Decimal, configure);
	}

	public function Boolean(name:String, ?configure:TableColumnBuilder->Void):TableBuilder {
		return Add(name, DatabaseColumnType.Boolean, configure);
	}

	public function DateTime(name:String, ?configure:TableColumnBuilder->Void):TableBuilder {
		return Add(name, DatabaseColumnType.DateTime, configure);
	}

	public function Date(name:String, ?configure:TableColumnBuilder->Void):TableBuilder {
		return Add(name, DatabaseColumnType.Date, configure);
	}

	public function PrimaryKey(name:String, columns:Array<String>):TableBuilder {
		definition.PrimaryKey(name, columns);
		return this;
	}

	public function ForeignKey(name:String, columns:Array<String>, referencedTable:String, referencedColumns:Array<String>):TableBuilder {
		definition.ForeignKey(name, columns, referencedTable, referencedColumns);
		return this;
	}

	public function Unique(name:String, columns:Array<String>):TableBuilder {
		definition.Unique(name, columns);
		return this;
	}

	public function Index(name:String, columns:Array<String>):TableBuilder {
		definition.Index(name, columns);
		return this;
	}

	public function Build():DatabaseTableDefinition {
		return definition;
	}
}

/** One column of a `TableBuilder`, configured. */
class TableColumnBuilder {
	public final Column:DatabaseColumnDefinition;

	public function new(column:DatabaseColumnDefinition) {
		this.Column = column;
	}

	public function Identity(?kind:IdentityKind):TableColumnBuilder {
		Column.IsAutoIncrement = true;
		Column.Identity = kind == null ? ByDefault : kind;
		Column.Nullable = false;
		return this;
	}

	public function NotNull():TableColumnBuilder {
		Column.Nullable = false;
		return this;
	}

	public function Nullable():TableColumnBuilder {
		Column.Nullable = true;
		return this;
	}

	public function MaxLength(length:Int):TableColumnBuilder {
		Column.MaxLength = length;
		return this;
	}

	public function Precision(precision:Int, scale:Int):TableColumnBuilder {
		Column.Precision = precision;
		Column.Scale = scale;
		return this;
	}

	public function Default(sql:String):TableColumnBuilder {
		Column.DefaultValue = sql;
		return this;
	}

	public function Collate(collation:String):TableColumnBuilder {
		Column.Collation = collation;
		return this;
	}
}
