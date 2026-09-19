package codequery.migrations;

import codequery.sqlexpressions.SqlType;

/**
	A schema as a document, and back again.

	What a migration records beside its SQL, so the next one can be worked out as the difference
	from it rather than from the database — which is what lets a migration be scaffolded without a
	connection to anything.
**/
class SchemaSnapshot {
	public static function ToYaml(schema:DatabaseSchema):String {
		return Yaml.Emit({
			version: schema.Version,
			name: schema.Name,
			tables: [
				for (table in schema.Tables)
					{
						name: table.Name,
						columns: [
							for (column in table.Columns)
								{
									name: column.Name,
									type: TypeName(column.Type),
									nullable: column.Nullable,
									primaryKey: column.PrimaryKey
								}
						]
					}
			],
			views: [
				for (view in schema.Views)
					{
						name: view.Name,
						select: view.Select,
						materialized: view.Materialized,
						strategy: Std.string(view.Strategy)
					}
			]
		});
	}

	public static function FromYaml(yaml:String):DatabaseSchema {
		final document = Yaml.Parse(yaml);
		if (document == null) {
			return DatabaseSchema.Empty();
		}

		final tables:Array<DatabaseTableDefinition> = [];
		final declared:Array<Dynamic> = Reflect.field(document, "tables");
		if (declared != null) {
			for (table in declared) {
				final columns:Array<DatabaseColumnDefinition> = [];
				final held:Array<Dynamic> = Reflect.field(table, "columns");
				if (held != null) {
					for (column in held) {
						columns.push(new DatabaseColumnDefinition(Reflect.field(column, "name"),
							TypeOf(Reflect.field(column, "type")), Reflect.field(column, "nullable") == true,
							Reflect.field(column, "primaryKey") == true));
					}
				}
				tables.push(new DatabaseTableDefinition(Reflect.field(table, "name"), columns));
			}
		}

		final views:Array<DatabaseViewDefinition> = [];
		final declaredViews:Array<Dynamic> = Reflect.field(document, "views");
		if (declaredViews != null) {
			for (view in declaredViews) {
				views.push(new DatabaseViewDefinition(Reflect.field(view, "name"), Reflect.field(view, "select"),
					Reflect.field(view, "materialized") == true,
					DatabaseViewDefinition.StrategyNamed(Reflect.field(view, "strategy"))));
			}
		}

		return new DatabaseSchema(tables, Reflect.field(document, "name"),
			Reflect.field(document, "version") == null ? 1 : Reflect.field(document, "version"), views);
	}

	/** A type as the snapshot writes it — its own spelling, not any dialect's. */
	public static function TypeName(type:SqlType):String {
		return switch type {
			case SqlInt: "int";
			case SqlBigInt: "bigint";
			case SqlFloat: "float";
			case SqlDecimal(precision, scale): 'decimal($precision,$scale)';
			case SqlBool: "bool";
			case SqlText: "text";
			case SqlVarChar(length): 'varchar($length)';
			case SqlDate: "date";
			case SqlTimestamp: "timestamp";
			case SqlUnknown: "unknown";
			case SqlSmallInt: "smallint";
			case SqlReal: "real";
			case SqlNamed(name): name;
		}
	}

	public static function TypeOf(name:String):SqlType {
		if (StringTools.startsWith(name, "varchar(")) {
			return SqlVarChar(Std.parseInt(name.substring(8, name.length - 1)));
		}
		if (StringTools.startsWith(name, "decimal(")) {
			final parts = name.substring(8, name.length - 1).split(",");
			return SqlDecimal(Std.parseInt(parts[0]), Std.parseInt(parts[1]));
		}
		return switch name {
			case "int": SqlInt;
			case "bigint": SqlBigInt;
			case "float": SqlFloat;
			case "bool": SqlBool;
			case "text": SqlText;
			case "date": SqlDate;
			case "timestamp": SqlTimestamp;
			case "smallint": SqlSmallInt;
			case "real": SqlReal;
			case "unknown": SqlUnknown;
			case named: SqlNamed(named);
		}
	}
}
