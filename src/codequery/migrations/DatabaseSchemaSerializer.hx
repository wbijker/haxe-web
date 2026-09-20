package codequery.migrations;

import codequery.migrations.DatabaseIndexDefinition;
import codequery.migrations.DatabaseTableConstraint;
import codequery.sqlexpressions.ColumnDefinition;
#if sys
import sys.io.File;
#end

/**
	A schema as JSON, and back — the C# `DatabaseSchemaSerializer`.

	Keys are camelCase, enums are written by name, nulls are left out, and a constraint carries a
	`type` discriminator, all as the C# serializer writes them, so a snapshot written by either can
	be read by the other. The same document shape is what the YAML snapshot is built from.
**/
class DatabaseSchemaSerializer {
	public static function Serialize(schema:DatabaseSchema):String {
		return haxe.Json.stringify(ToDocument(schema), null, "  ");
	}

	public static function Deserialize(json:String):DatabaseSchema {
		final document = haxe.Json.parse(json);
		if (document == null) {
			throw "Failed to deserialize schema: result was null";
		}
		return FromDocument(document);
	}

	/** Writes the JSON to an output, as C# writes it to a stream. */
	public static function SerializeTo(schema:DatabaseSchema, output:haxe.io.Output):Void {
		output.writeString(Serialize(schema));
	}

	/** Reads a schema from an input, as C# reads it from a stream. */
	public static function DeserializeFrom(input:haxe.io.Input):DatabaseSchema {
		return Deserialize(input.readAll().toString());
	}

	public static function SaveToFile(schema:DatabaseSchema, filePath:String):Void {
		#if sys
		File.saveContent(filePath, Serialize(schema));
		#else
		throw "A schema is saved to disk, which this target has none of";
		#end
	}

	public static function LoadFromFile(filePath:String):DatabaseSchema {
		#if sys
		return Deserialize(File.getContent(filePath));
		#else
		throw "A schema is loaded from disk, which this target has none of";
		#end
	}

	public static function SerializeTable(table:DatabaseTableDefinition):String {
		return haxe.Json.stringify(TableDocument(table), null, "  ");
	}

	public static function DeserializeTable(json:String):DatabaseTableDefinition {
		final document = haxe.Json.parse(json);
		if (document == null) {
			throw "Failed to deserialize table definition: result was null";
		}
		return TableFromDocument(document);
	}

	// ---- to a document ---------------------------------------------------------------------------

	/** The schema as plain maps, lists and scalars, with nothing null in it. */
	public static function ToDocument(schema:DatabaseSchema):Dynamic {
		final document:Dynamic = {};
		Reflect.setField(document, "version", schema.Version);
		Set(document, "name", schema.Name);
		Set(document, "createdAt", schema.CreatedAt == null ? null : DateTools.format(schema.CreatedAt, "%Y-%m-%dT%H:%M:%S"));
		Set(document, "description", schema.Description);
		Set(document, "provider", schema.Provider);
		Reflect.setField(document, "tables", schema.Tables.map(TableDocument));
		return document;
	}

	public static function TableDocument(table:DatabaseTableDefinition):Dynamic {
		final document:Dynamic = {};
		Reflect.setField(document, "tableName", table.TableName);
		Set(document, "schema", table.Schema);
		Reflect.setField(document, "columns", table.Columns.map(ColumnDocument));
		Reflect.setField(document, "constraints", table.Constraints.map(ConstraintDocument));
		Reflect.setField(document, "indexes", table.Indexes.map(IndexDocument));
		return document;
	}

	static function ColumnDocument(column:DatabaseColumnDefinition):Dynamic {
		final document:Dynamic = {};
		Reflect.setField(document, "name", column.Name);
		Reflect.setField(document, "type", EnumName(column.Type));
		Reflect.setField(document, "isNullable", column.IsNullable);
		Reflect.setField(document, "isAutoIncrement", column.IsAutoIncrement);
		// The ordinary form is not written down; a snapshot says only what differs from it.
		if (column.Identity != ByDefault) {
			Reflect.setField(document, "identity", EnumName(column.Identity));
		}
		if (column.ServerGeneratedGuid) {
			Reflect.setField(document, "serverGeneratedGuid", true);
		}
		Set(document, "defaultValue", column.DefaultValue);
		Set(document, "maxLength", column.MaxLength);
		Set(document, "precision", column.Precision);
		Set(document, "scale", column.Scale);
		Set(document, "collation", column.Collation);
		Set(document, "comment", column.Comment);
		Set(document, "generatedExpression", column.GeneratedExpression);
		Set(document, "generatedStored", column.GeneratedStored);
		Set(document, "ordinalIndex", column.OrdinalIndex);
		return document;
	}

	static function ConstraintDocument(constraint:DatabaseTableConstraint):Dynamic {
		final document:Dynamic = {};
		Reflect.setField(document, "type", Std.string(constraint.ConstraintType()).toLowerCase());
		Set(document, "name", constraint.Name);

		final pk = Std.downcast(constraint, DatabasePrimaryKeyConstraint);
		if (pk != null) {
			Reflect.setField(document, "columns", pk.Columns.copy());
			Reflect.setField(document, "generation", Std.string(pk.Generation).toLowerCase());
		}
		final fk = Std.downcast(constraint, DatabaseForeignKeyConstraint);
		if (fk != null) {
			Reflect.setField(document, "columns", fk.Columns.copy());
			Reflect.setField(document, "referencedTable", fk.ReferencedTable);
			Set(document, "referencedSchema", fk.ReferencedSchema);
			Reflect.setField(document, "referencedColumns", fk.ReferencedColumns.copy());
			Reflect.setField(document, "onDelete", Std.string(fk.OnDelete).toLowerCase());
			Reflect.setField(document, "onUpdate", Std.string(fk.OnUpdate).toLowerCase());
		}
		final uq = Std.downcast(constraint, DatabaseUniqueConstraint);
		if (uq != null) {
			Reflect.setField(document, "columns", uq.Columns.copy());
		}
		final ck = Std.downcast(constraint, DatabaseCheckConstraint);
		if (ck != null) {
			Reflect.setField(document, "expression", ck.Expression);
		}
		final def = Std.downcast(constraint, DatabaseDefaultConstraint);
		if (def != null) {
			Reflect.setField(document, "columnName", def.ColumnName);
			Reflect.setField(document, "expression", def.Expression);
		}
		return document;
	}

	static function IndexDocument(index:DatabaseIndexDefinition):Dynamic {
		final document:Dynamic = {};
		Reflect.setField(document, "name", index.Name);
		Reflect.setField(document, "columns", index.Columns.map(column -> {
			final held:Dynamic = {};
			Reflect.setField(held, "columnName", column.ColumnName);
			Reflect.setField(held, "sortOrder", EnumName(column.SortOrder));
			held;
		}));
		Reflect.setField(document, "isUnique", index.IsUnique);
		Reflect.setField(document, "isClustered", index.IsClustered);
		Set(document, "filterExpression", index.FilterExpression);
		Reflect.setField(document, "includeColumns", index.IncludeColumns.copy());
		Set(document, "method", index.Method);
		return document;
	}

	static function Set(document:Dynamic, name:String, value:Dynamic):Void {
		if (value != null) {
			Reflect.setField(document, name, value);
		}
	}

	/** An enum value by name, camelCased as the C# serializer writes it: `VarChar` is `varChar`. */
	static function EnumName(value:EnumValue):String {
		final name = Type.enumConstructor(value);
		return name.charAt(0).toLowerCase() + name.substr(1);
	}

	// ---- from a document -------------------------------------------------------------------------

	public static function FromDocument(document:Dynamic):DatabaseSchema {
		final schema = new DatabaseSchema();
		if (Reflect.field(document, "version") != null) {
			schema.Version = Reflect.field(document, "version");
		}
		schema.Name = Reflect.field(document, "name");
		schema.Description = Reflect.field(document, "description");
		schema.Provider = Reflect.field(document, "provider");
		final created:Null<String> = Reflect.field(document, "createdAt");
		if (created != null) {
			schema.CreatedAt = try Date.fromString(StringTools.replace(created.substr(0, 19), "T", " ")) catch (_:Dynamic) null;
		}
		final tables:Null<Array<Dynamic>> = Reflect.field(document, "tables");
		if (tables != null) {
			schema.Tables = tables.map(TableFromDocument);
		}
		return schema;
	}

	public static function TableFromDocument(document:Dynamic):DatabaseTableDefinition {
		final tableName:String = Reflect.field(document, "tableName");
		final schema:Null<String> = Reflect.field(document, "schema");
		final table = new DatabaseTableDefinition(tableName, [], schema);
		final columns:Null<Array<Dynamic>> = Reflect.field(document, "columns");
		if (columns != null) {
			table.Columns = columns.map(ColumnFromDocument);
		}
		final constraints:Null<Array<Dynamic>> = Reflect.field(document, "constraints");
		if (constraints != null) {
			table.Constraints = constraints.map(ConstraintFromDocument);
		}
		final indexes:Null<Array<Dynamic>> = Reflect.field(document, "indexes");
		if (indexes != null) {
			table.Indexes = indexes.map(IndexFromDocument);
		}
		return table;
	}

	static function ColumnFromDocument(document:Dynamic):DatabaseColumnDefinition {
		final name:String = Reflect.field(document, "name");
		final column = DatabaseColumnDefinition.Of(name, ColumnType(Reflect.field(document, "type")),
			Reflect.field(document, "isNullable") != false);
		column.IsAutoIncrement = Reflect.field(document, "isAutoIncrement") == true;
		column.Identity = Identity(Reflect.field(document, "identity"));
		column.ServerGeneratedGuid = Reflect.field(document, "serverGeneratedGuid") == true;
		column.DefaultValue = Reflect.field(document, "defaultValue");
		column.MaxLength = Reflect.field(document, "maxLength");
		column.Precision = Reflect.field(document, "precision");
		column.Scale = Reflect.field(document, "scale");
		column.Collation = Reflect.field(document, "collation");
		column.Comment = Reflect.field(document, "comment");
		column.GeneratedExpression = Reflect.field(document, "generatedExpression");
		column.GeneratedStored = Reflect.field(document, "generatedStored");
		column.OrdinalIndex = Reflect.field(document, "ordinalIndex");
		return column;
	}

	static function ConstraintFromDocument(document:Dynamic):DatabaseTableConstraint {
		var type:Null<String> = Reflect.field(document, "type");
		if (type == null) {
			type = Reflect.field(document, "constraintType");
		}
		if (type == null || type == "") {
			throw "Missing 'type' or 'constraintType' discriminator";
		}
		final name:Null<String> = Reflect.field(document, "name");
		return switch type.toLowerCase() {
			case "primarykey":
				new DatabasePrimaryKeyConstraint(name, Strings(Reflect.field(document, "columns")),
					Generation(Reflect.field(document, "generation")));
			case "foreignkey":
				new DatabaseForeignKeyConstraint(name, Strings(Reflect.field(document, "columns")),
					Reflect.field(document, "referencedTable"), Strings(Reflect.field(document, "referencedColumns")),
					ForeignKeyAction(Reflect.field(document, "onDelete")), ForeignKeyAction(Reflect.field(document, "onUpdate")),
					Reflect.field(document, "referencedSchema"));
			case "unique":
				new DatabaseUniqueConstraint(name, Strings(Reflect.field(document, "columns")));
			case "check":
				new DatabaseCheckConstraint(name, Reflect.field(document, "expression"));
			case "default":
				new DatabaseDefaultConstraint(name, Reflect.field(document, "columnName"), Reflect.field(document, "expression"));
			case _:
				throw 'Unknown constraint type: $type';
		}
	}

	static function IndexFromDocument(document:Dynamic):DatabaseIndexDefinition {
		final columns:Null<Array<Dynamic>> = Reflect.field(document, "columns");
		final index = new DatabaseIndexDefinition(Reflect.field(document, "name"),
			columns == null ? [] : columns.map(held -> new DatabaseIndexColumn(Reflect.field(held, "columnName"),
				SortOrder(Reflect.field(held, "sortOrder")))),
			Reflect.field(document, "isUnique") == true, Reflect.field(document, "isClustered") == true,
			Reflect.field(document, "filterExpression"), Reflect.field(document, "method"));
		final include:Null<Array<Dynamic>> = Reflect.field(document, "includeColumns");
		if (include != null) {
			index.IncludeColumns = Strings(include);
		}
		return index;
	}

	static function Strings(values:Null<Array<Dynamic>>):Array<String> {
		return values == null ? [] : [for (value in values) Std.string(value)];
	}

	/** An enum value by name, read regardless of case, as the C# converter reads it. */
	static function EnumByName<T>(e:Enum<T>, name:Null<String>, fallback:T):T {
		if (name == null) {
			return fallback;
		}
		for (constructor in Type.getEnumConstructs(e)) {
			if (constructor.toLowerCase() == name.toLowerCase()) {
				return Type.createEnum(e, constructor);
			}
		}
		return fallback;
	}

	public static function ColumnType(name:Null<String>):DatabaseColumnType {
		return EnumByName(DatabaseColumnType, name, Unknown);
	}

	static function Identity(name:Null<String>):IdentityKind {
		return EnumByName(IdentityKind, name, ByDefault);
	}

	static function Generation(name:Null<String>):codequery.ValueGeneration {
		return EnumByName(codequery.ValueGeneration, name, ServerGenerated);
	}

	static function ForeignKeyAction(name:Null<String>):DatabaseForeignKeyAction {
		return EnumByName(DatabaseForeignKeyAction, name, NoAction);
	}

	static function SortOrder(name:Null<String>):DatabaseSortOrder {
		return EnumByName(DatabaseSortOrder, name, Ascending);
	}
}
