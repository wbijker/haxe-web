package codequery.migrations;

#if macro
import codequery.inspection.SchemaInspector;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

/**
	What the column builders' macros share: reading the entity behind a builder, the column a
	property lambda names, and the builder that column's type gets.
**/
class ColumnBuilderMacros {
	/** The entity an `EntityTableBuilder<T>` expression is over. */
	public static function EntityOf(table:Expr):ClassType {
		return switch Context.typeof(table).follow() {
			case TInst(_, [entity]):
				switch entity.follow() {
					case TInst(t, _): t.get();
					case t: Context.error('${t.toString()} is not an entity class', table.pos);
				}
			case t: Context.error('${t.toString()} is not a table builder', table.pos);
		}
	}

	/** The field a property lambda names: `c -> c.tripNumber` is `tripNumber`. */
	public static function FieldOf(entity:ClassType, property:Expr):ClassField {
		final name = switch property.expr {
			case EFunction(_, {args: [arg], expr: body}):
				switch Unwrap(body).expr {
					case EField({expr: EConst(CIdent(param))}, field, _) if (param == arg.name): field;
					case _: Context.error("Expected a property accessor, e.g. x -> x.property", property.pos);
				}
			case _: Context.error("Expected a property accessor, e.g. x -> x.property", property.pos);
		}
		for (field in SchemaInspector.ColumnFields(entity)) {
			if (field.name == name) {
				return field;
			}
		}
		return Context.error('${entity.name} has no column field "$name"', property.pos);
	}

	static function Unwrap(e:Expr):Expr {
		return switch e.expr {
			case EReturn(inner) if (inner != null): Unwrap(inner);
			case EParenthesis(inner) | EMeta(_, inner) | EBlock([inner]): Unwrap(inner);
			case _: e;
		}
	}

	/** The mapped column a property lambda names. */
	public static function ColumnNameOf(entity:ClassType, property:Expr):String {
		return SchemaInspector.ColumnNameOf(FieldOf(entity, property));
	}

	/**
		`table.Column(x -> x.property)`: the builder for the column, typed by what the property is —
		a string gets `StringColumnBuilder`, a `Decimal` the one with `Precision`, and so on.
	**/
	public static function ColumnCall(table:Expr, property:Expr):Expr {
		final entity = EntityOf(table);
		final field = FieldOf(entity, property);
		final kind = SchemaInspector.Classify(field.type);
		if (kind.type == "Unknown" || kind.skip) {
			Context.error('${entity.name}.${field.name} has no column type', property.pos);
		}
		final name = SchemaInspector.ColumnNameOf(field);
		final type = macro $p{["codequery", "migrations", "DatabaseColumnType", kind.type]};
		final nullable = kind.nullable;
		final entityType = switch Context.typeof(table).follow() {
			case TInst(_, [e]): TypeTools.toComplexType(e);
			case _: Context.error("Not a table builder", table.pos);
		}
		final propertyType = TypeTools.toComplexType(field.type);

		return switch kind.type {
			case "VarChar" | "Char" | "Text" | "NText" | "NVarChar" | "NChar":
				macro($table.StringColumn($v{name}, $type, $v{nullable}) : codequery.migrations.StringColumnBuilder<$entityType>);
			case "VarBinary" | "Binary" | "Blob":
				macro($table.BinaryColumn($v{name}, $type, $v{nullable}) : codequery.migrations.BinaryColumnBuilder<$entityType>);
			case "Decimal":
				macro($table.DecimalColumn($v{name}, $type, $v{nullable}) : codequery.migrations.DecimalColumnBuilder<$entityType, $propertyType>);
			case "DateTime" | "Date" | "DateTimeOffset" | "Timestamp":
				macro($table.DateTimeColumn($v{name}, $type, $v{nullable}) : codequery.migrations.DateTimeColumnBuilder<$entityType, $propertyType>);
			case "Time":
				macro($table.TimeColumn($v{name}, $type, $v{nullable}) : codequery.migrations.TimeColumnBuilder<$entityType, $propertyType>);
			case _:
				macro($table.PlainColumn($v{name}, $type, $v{nullable}, $v{kind.isGuid}) : codequery.migrations.ColumnBuilder<$entityType, $propertyType>);
		}
	}

	/** The `DatabaseColumnType` a lambda's answer is stored as — for `Convert`. */
	public static function ProviderTypeOf(toProvider:Expr):Expr {
		final returned = switch Context.typeof(toProvider).follow() {
			case TFun(_, ret): ret;
			case t: Context.error('${t.toString()} is not a conversion function', toProvider.pos);
		}
		final kind = SchemaInspector.Classify(returned);
		return macro $p{["codequery", "migrations", "DatabaseColumnType", kind.type]};
	}
}
#end
