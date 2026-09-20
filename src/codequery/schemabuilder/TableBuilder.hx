package codequery.schemabuilder;

import codequery.migrations.*;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.migrations.DatabaseColumnDefinition;
import codequery.migrations.DatabaseColumnType;
import codequery.migrations.DatabaseIndexDefinition;
import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.DatabaseTableDefinition;

/**
	A table definition built by name — `TableBuilder.Create().Table("Users").Int("Id").Build()` —
	with a builder per column type saying what that type can be told. The C# `SchemaBuilder`
	namespace's builders, in one module.
**/
class TableBuilder {
	var tableName = "";
	var schema:Null<String>;
	final columns:Array<DatabaseColumnDefinition> = [];
	final constraints:Array<DatabaseTableConstraint> = [];
	final indexes:Array<DatabaseIndexDefinition> = [];

	public function new() {}

	public static function Create():TableBuilder {
		return new TableBuilder();
	}

	public function Table(tableName:String):TableBuilder {
		this.tableName = tableName;
		return this;
	}

	public function Schema(schema:String):TableBuilder {
		this.schema = schema;
		return this;
	}

	function Add<T:ColumnBuilderBase<T>>(builder:T, configure:Null<T->Void>):TableBuilder {
		if (configure != null) {
			configure(builder);
		}
		columns.push(builder.Build());
		return this;
	}

	// String columns
	public function String(name:String, ?configure:StringColumnBuilder->Void):TableBuilder return Add(new StringColumnBuilder(name), configure);
	public function Char(name:String, length:Int, ?configure:CharColumnBuilder->Void):TableBuilder return Add(new CharColumnBuilder(name, length), configure);
	public function Text(name:String, ?configure:TextColumnBuilder->Void):TableBuilder return Add(new TextColumnBuilder(name), configure);

	// Numeric columns
	public function Int(name:String, ?configure:IntColumnBuilder->Void):TableBuilder return Add(new IntColumnBuilder(name), configure);
	public function BigInt(name:String, ?configure:BigIntColumnBuilder->Void):TableBuilder return Add(new BigIntColumnBuilder(name), configure);
	public function SmallInt(name:String, ?configure:SmallIntColumnBuilder->Void):TableBuilder return Add(new SmallIntColumnBuilder(name), configure);
	public function TinyInt(name:String, ?configure:TinyIntColumnBuilder->Void):TableBuilder return Add(new TinyIntColumnBuilder(name), configure);
	public function Decimal(name:String, ?configure:DecimalColumnBuilder->Void):TableBuilder return Add(new DecimalColumnBuilder(name), configure);
	public function Float(name:String, ?configure:FloatColumnBuilder->Void):TableBuilder return Add(new FloatColumnBuilder(name), configure);
	public function Double(name:String, ?configure:DoubleColumnBuilder->Void):TableBuilder return Add(new DoubleColumnBuilder(name), configure);

	// Boolean
	public function Boolean(name:String, ?configure:BooleanColumnBuilder->Void):TableBuilder return Add(new BooleanColumnBuilder(name), configure);

	// Date/time columns
	public function DateTime(name:String, ?configure:DateTimeColumnBuilder->Void):TableBuilder return Add(new DateTimeColumnBuilder(name), configure);
	public function Date(name:String, ?configure:DateColumnBuilder->Void):TableBuilder return Add(new DateColumnBuilder(name), configure);
	public function Time(name:String, ?configure:TimeColumnBuilder->Void):TableBuilder return Add(new TimeColumnBuilder(name), configure);
	public function DateTimeOffset(name:String, ?configure:DateTimeOffsetColumnBuilder->Void):TableBuilder return Add(new DateTimeOffsetColumnBuilder(name), configure);
	public function Timestamp(name:String, ?configure:TimestampColumnBuilder->Void):TableBuilder return Add(new TimestampColumnBuilder(name), configure);

	// Binary columns
	public function Binary(name:String, ?configure:BinaryColumnBuilder->Void):TableBuilder return Add(new BinaryColumnBuilder(name), configure);
	public function Blob(name:String, ?configure:BlobColumnBuilder->Void):TableBuilder return Add(new BlobColumnBuilder(name), configure);

	// Special types
	public function Guid(name:String, ?configure:GuidColumnBuilder->Void):TableBuilder return Add(new GuidColumnBuilder(name), configure);
	public function Json(name:String, ?configure:JsonColumnBuilder->Void):TableBuilder return Add(new JsonColumnBuilder(name), configure);
	public function Xml(name:String, ?configure:XmlColumnBuilder->Void):TableBuilder return Add(new XmlColumnBuilder(name), configure);

	// Constraints

	/** A primary key: `PrimaryKey("PK_Users", ["Id"])`, or `PrimaryKey(["Id"])` named for the table. */
	public function PrimaryKey(nameOrColumns:Dynamic, ?columns:Array<String>):TableBuilder {
		if (Std.isOfType(nameOrColumns, std.String)) {
			constraints.push(new DatabasePrimaryKeyConstraint((nameOrColumns : String), columns));
		} else {
			constraints.push(new DatabasePrimaryKeyConstraint('PK_$tableName', (nameOrColumns : Array<String>)));
		}
		return this;
	}

	public function ForeignKey(name:String, configure:ForeignKeyBuilder->Void):TableBuilder {
		final builder = new ForeignKeyBuilder(name);
		configure(builder);
		constraints.push(builder.Build());
		return this;
	}

	/** A unique constraint: `Unique("UQ_x", ["Email"])`, or `Unique(["Email"])` named for the columns. */
	public function Unique(nameOrColumns:Dynamic, ?columns:Array<String>):TableBuilder {
		if (Std.isOfType(nameOrColumns, std.String)) {
			constraints.push(new DatabaseUniqueConstraint((nameOrColumns : String), columns));
		} else {
			final named:Array<String> = nameOrColumns;
			constraints.push(new DatabaseUniqueConstraint('UQ_${tableName}_${named.join("_")}', named));
		}
		return this;
	}

	public function Check(name:String, expression:String):TableBuilder {
		constraints.push(new DatabaseCheckConstraint(name, expression));
		return this;
	}

	// Indexes

	/** An index: `Index("IX_x", ["Email"])`, or `Index("IX_x", idx -> idx.Column("Email").Unique())`. */
	public function Index(name:String, columnsOrConfigure:Dynamic):TableBuilder {
		if (Reflect.isFunction(columnsOrConfigure)) {
			final builder = new IndexBuilder(name);
			(columnsOrConfigure : IndexBuilder->Void)(builder);
			indexes.push(builder.Build());
		} else {
			final columns:Array<String> = columnsOrConfigure;
			indexes.push(new DatabaseIndexDefinition(name, columns.map(c -> new DatabaseIndexColumn(c))));
		}
		return this;
	}

	public function Build():DatabaseTableDefinition {
		if (tableName == null || tableName == "") {
			throw "Table name is required";
		}
		// Each column knows its place, so a rename can be told apart from a drop and an add.
		for (index => column in columns) {
			column.OrdinalIndex = index;
		}
		final definition = new DatabaseTableDefinition(tableName, schema);
		definition.Columns = columns;
		definition.Constraints = constraints;
		definition.Indexes = indexes;
		return definition;
	}
}

/** What every column builder can be told, whatever its type. */
class ColumnBuilderBase<TBuilder> {
	final Definition:DatabaseColumnDefinition;

	function new(name:String, type:DatabaseColumnType) {
		Definition = new DatabaseColumnDefinition(name, type, false);
	}

	function Self():TBuilder {
		return cast this;
	}

	public function Nullable(nullable:Bool = true):TBuilder {
		Definition.IsNullable = nullable;
		return Self();
	}

	public function NotNull():TBuilder {
		Definition.IsNullable = false;
		return Self();
	}

	public function Comment(comment:String):TBuilder {
		Definition.Comment = comment;
		return Self();
	}

	public function Build():DatabaseColumnDefinition {
		return Definition;
	}
}

class StringColumnBuilder extends ColumnBuilderBase<StringColumnBuilder> {
	public function new(name:String) super(name, VarChar);
	public function MaxLength(length:Int):StringColumnBuilder { Definition.MaxLength = length; return this; }
	public function DefaultValue(value:String):StringColumnBuilder { Definition.DefaultValue = value; return this; }
	public function Collation(collation:String):StringColumnBuilder { Definition.Collation = collation; return this; }
}

class CharColumnBuilder extends ColumnBuilderBase<CharColumnBuilder> {
	public function new(name:String, length:Int) { super(name, Char); Definition.MaxLength = length; }
	public function DefaultValue(value:String):CharColumnBuilder { Definition.DefaultValue = value; return this; }
	public function Collation(collation:String):CharColumnBuilder { Definition.Collation = collation; return this; }
}

class TextColumnBuilder extends ColumnBuilderBase<TextColumnBuilder> {
	public function new(name:String) super(name, Text);
	public function DefaultValue(value:String):TextColumnBuilder { Definition.DefaultValue = value; return this; }
}

class IntColumnBuilder extends ColumnBuilderBase<IntColumnBuilder> {
	public function new(name:String) super(name, Int);
	public function DefaultValue(value:Int):IntColumnBuilder { Definition.DefaultValue = Std.string(value); return this; }
	public function Identity(identity:IdentityKind = ByDefault):IntColumnBuilder { Definition.IsAutoIncrement = true; Definition.Identity = identity; return this; }
}

class BigIntColumnBuilder extends ColumnBuilderBase<BigIntColumnBuilder> {
	public function new(name:String) super(name, BigInt);
	public function DefaultValue(value:Int):BigIntColumnBuilder { Definition.DefaultValue = Std.string(value); return this; }
	public function Identity(identity:IdentityKind = ByDefault):BigIntColumnBuilder { Definition.IsAutoIncrement = true; Definition.Identity = identity; return this; }
}

class SmallIntColumnBuilder extends ColumnBuilderBase<SmallIntColumnBuilder> {
	public function new(name:String) super(name, SmallInt);
	public function DefaultValue(value:Int):SmallIntColumnBuilder { Definition.DefaultValue = Std.string(value); return this; }
}

class TinyIntColumnBuilder extends ColumnBuilderBase<TinyIntColumnBuilder> {
	public function new(name:String) super(name, TinyInt);
	public function DefaultValue(value:Int):TinyIntColumnBuilder { Definition.DefaultValue = Std.string(value); return this; }
}

class DecimalColumnBuilder extends ColumnBuilderBase<DecimalColumnBuilder> {
	public function new(name:String) { super(name, Decimal); Definition.Precision = 18; Definition.Scale = 2; }
	public function Precision(precision:Int, scale:Int):DecimalColumnBuilder { Definition.Precision = precision; Definition.Scale = scale; return this; }
	public function DefaultValue(value:Float):DecimalColumnBuilder { Definition.DefaultValue = Std.string(value); return this; }
}

class FloatColumnBuilder extends ColumnBuilderBase<FloatColumnBuilder> {
	public function new(name:String) super(name, Float);
	public function DefaultValue(value:Float):FloatColumnBuilder { Definition.DefaultValue = Std.string(value); return this; }
}

class DoubleColumnBuilder extends ColumnBuilderBase<DoubleColumnBuilder> {
	public function new(name:String) super(name, Double);
	public function DefaultValue(value:Float):DoubleColumnBuilder { Definition.DefaultValue = Std.string(value); return this; }
}

class BooleanColumnBuilder extends ColumnBuilderBase<BooleanColumnBuilder> {
	public function new(name:String) super(name, Boolean);
	public function DefaultValue(value:Bool):BooleanColumnBuilder { Definition.DefaultValue = value ? "true" : "false"; return this; }
}

class DateTimeColumnBuilder extends ColumnBuilderBase<DateTimeColumnBuilder> {
	public function new(name:String) super(name, DateTime);
	public function DefaultValue(expression:String):DateTimeColumnBuilder { Definition.DefaultValue = expression; return this; }
	public function DefaultCurrentTimestamp():DateTimeColumnBuilder { Definition.DefaultValue = "CURRENT_TIMESTAMP"; return this; }
}

class DateColumnBuilder extends ColumnBuilderBase<DateColumnBuilder> {
	public function new(name:String) super(name, Date);
	public function DefaultValue(expression:String):DateColumnBuilder { Definition.DefaultValue = expression; return this; }
	public function DefaultCurrentDate():DateColumnBuilder { Definition.DefaultValue = "CURRENT_DATE"; return this; }
}

class TimeColumnBuilder extends ColumnBuilderBase<TimeColumnBuilder> {
	public function new(name:String) super(name, Time);
	public function DefaultValue(expression:String):TimeColumnBuilder { Definition.DefaultValue = expression; return this; }
}

class DateTimeOffsetColumnBuilder extends ColumnBuilderBase<DateTimeOffsetColumnBuilder> {
	public function new(name:String) super(name, DateTimeOffset);
	public function DefaultValue(expression:String):DateTimeOffsetColumnBuilder { Definition.DefaultValue = expression; return this; }
}

class TimestampColumnBuilder extends ColumnBuilderBase<TimestampColumnBuilder> {
	public function new(name:String) super(name, Timestamp);
}

class BinaryColumnBuilder extends ColumnBuilderBase<BinaryColumnBuilder> {
	public function new(name:String) { super(name, VarBinary); Definition.MaxLength = 255; }
	public function MaxLength(length:Int):BinaryColumnBuilder { Definition.MaxLength = length; return this; }
	public function FixedLength(length:Int):BinaryColumnBuilder { Definition.Type = Binary; Definition.MaxLength = length; return this; }
}

class BlobColumnBuilder extends ColumnBuilderBase<BlobColumnBuilder> {
	public function new(name:String) super(name, Blob);
}

class GuidColumnBuilder extends ColumnBuilderBase<GuidColumnBuilder> {
	public function new(name:String) super(name, Guid);
	public function DefaultNewGuid():GuidColumnBuilder { Definition.DefaultValue = "NEWID()"; return this; }
	public function DefaultValue(value:codequery.Guid):GuidColumnBuilder { Definition.DefaultValue = value.toString(); return this; }
}

class JsonColumnBuilder extends ColumnBuilderBase<JsonColumnBuilder> {
	public function new(name:String) super(name, Json);
	public function DefaultValue(json:String):JsonColumnBuilder { Definition.DefaultValue = json; return this; }
}

class XmlColumnBuilder extends ColumnBuilderBase<XmlColumnBuilder> {
	public function new(name:String) super(name, Xml);
}

/** A foreign key, built by naming its columns and what they reference. */
class ForeignKeyBuilder {
	final name:String;
	final columns:Array<String> = [];
	var referencedTable = "";
	var referencedSchema:Null<String>;
	final referencedColumns:Array<String> = [];
	var onDelete:DatabaseForeignKeyAction = NoAction;
	var onUpdate:DatabaseForeignKeyAction = NoAction;

	public function new(name:String) {
		this.name = name;
	}

	public function Column(column:String):ForeignKeyBuilder {
		columns.push(column);
		return this;
	}

	public function Columns(columns:Array<String>):ForeignKeyBuilder {
		for (column in columns) this.columns.push(column);
		return this;
	}

	/** `References("Users", ["Id"])`, or `References("Users", "Id")` for one column. */
	public function References(table:String, columns:Dynamic):ForeignKeyBuilder {
		referencedTable = table;
		if (Std.isOfType(columns, std.String)) {
			referencedColumns.push(columns);
		} else {
			for (column in (columns : Array<String>)) referencedColumns.push(column);
		}
		return this;
	}

	public function ReferencesWithSchema(schema:String, table:String, columns:Array<String>):ForeignKeyBuilder {
		referencedSchema = schema;
		return References(table, columns);
	}

	public function OnDelete(action:DatabaseForeignKeyAction):ForeignKeyBuilder {
		onDelete = action;
		return this;
	}

	public function OnUpdate(action:DatabaseForeignKeyAction):ForeignKeyBuilder {
		onUpdate = action;
		return this;
	}

	public function Cascade():ForeignKeyBuilder {
		onDelete = DatabaseForeignKeyAction.Cascade;
		onUpdate = DatabaseForeignKeyAction.Cascade;
		return this;
	}

	public function Build():DatabaseForeignKeyConstraint {
		return new DatabaseForeignKeyConstraint(name, columns, referencedTable, referencedColumns, onDelete, onUpdate, referencedSchema);
	}
}

/** An index, built by naming its columns and how it is read. */
class IndexBuilder {
	final name:String;
	final columns:Array<DatabaseIndexColumn> = [];
	var isUnique = false;
	var isClustered = false;
	var filterExpression:Null<String>;
	final includeColumns:Array<String> = [];
	var method:Null<String>;

	public function new(name:String) {
		this.name = name;
	}

	public function Column(column:String, ?sortOrder:DatabaseSortOrder):IndexBuilder {
		columns.push(new DatabaseIndexColumn(column, sortOrder));
		return this;
	}

	public function Columns(columns:Array<String>):IndexBuilder {
		for (column in columns) this.columns.push(new DatabaseIndexColumn(column));
		return this;
	}

	public function Ascending(column:String):IndexBuilder {
		return Column(column, DatabaseSortOrder.Ascending);
	}

	public function Descending(column:String):IndexBuilder {
		return Column(column, DatabaseSortOrder.Descending);
	}

	public function Unique():IndexBuilder {
		isUnique = true;
		return this;
	}

	public function Clustered():IndexBuilder {
		isClustered = true;
		return this;
	}

	public function Filter(expression:String):IndexBuilder {
		filterExpression = expression;
		return this;
	}

	public function Include(columns:Array<String>):IndexBuilder {
		for (column in columns) includeColumns.push(column);
		return this;
	}

	public function Using(method:String):IndexBuilder {
		this.method = method;
		return this;
	}

	public function Build():DatabaseIndexDefinition {
		final index = new DatabaseIndexDefinition(name, columns, isUnique, isClustered, filterExpression, method);
		index.IncludeColumns = includeColumns;
		return index;
	}
}
