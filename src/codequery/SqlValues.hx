package codequery;

import codequery.queries.ISelectQuery;
import codequery.queries.SelectQueryImpl;
import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.ProjectionMember;
import codequery.sqlexpressions.ProjectionSqlExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;
import codequery.sqlexpressions.ValueSqlSource;
#if macro
import codequery.sqlexpressions.ColumnsBuilder;
import codequery.sqlexpressions.ExpressionConverter;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/**
	A strongly-typed constant collection as a query — SQL's VALUES table constructor:

	```haxe
	SqlValues.of(Widget, [new Widget(1, "a"), new Widget(2, "b")])   // (VALUES (1, 'a'), (2, 'b')) AS t0(id, name)
	SqlValues.of(Int, [7, 8])                                          // (VALUES (7), (8)) AS t0(value)
	```

	An entity's columns are its public fields, as they are for a table; a scalar is one column,
	`value`, which is what makes a list of ids the typed way to write `IN`.

	C#'s `SqlValues<T>.Create(items)`. Haxe cannot read a type parameter at runtime, so the type is
	named where the call is made and its columns are read off it while compiling.
**/
class SqlValues {
	/** A query over the rows, of the type named: `SqlValues.of(Widget, rows)`. */
	public static macro function of(type:Expr, items:Expr):Expr {
		final held = Context.getType(switch type.expr {
			case EConst(CIdent(name)): name;
			case EField(_, _, _): new haxe.macro.Printer().printExpr(type);
			case _: Context.error("Name the row type, e.g. SqlValues.of(Widget, rows)", type.pos);
		});

		final columns:Array<Expr> = [];
		final cells:Array<Expr> = [];
		final scalar = IsScalar(held);
		if (scalar) {
			columns.push(macro $v{ScalarColumn});
			cells.push(ExpressionConverter.ValuedAs(macro item, held));
		} else {
			final row = switch held.follow() {
				case TInst(t, _): t.get();
				case t: Context.error('${t.toString()} is not an entity class or a scalar', type.pos);
			}
			for (field in row.fields.get()) {
				if (!IsColumn(field)) {
					continue;
				}
				final name = field.name;
				columns.push(macro $v{ColumnsBuilder.ColumnNameOf(field)});
				cells.push(ExpressionConverter.ValuedAs(macro item.$name, field.type));
			}
		}

		final columnList = {expr: EArrayDecl(columns), pos: type.pos};
		final cellList = {expr: EArrayDecl(cells), pos: type.pos};
		final path = held.toComplexType();
		return macro(cast codequery.SqlValues.Over($columnList, [for (item in ($items : Array<$path>)) $cellList])
			: codequery.queries.ISelectQuery<$path>);
	}

	/** The one column a list of scalars has. */
	public static final ScalarColumn = "value";

	/** The query over a constant table of these columns and rows; what `of` compiles down to. */
	public static function Over(columns:Array<String>, rows:Array<Array<ISqlExpression>>):SelectQueryImpl {
		final context = new SourceContext();
		final source = new ValueSqlSource(rows, columns, context.GenerateAlias());
		context.Sources.push(source);

		// The constant table is read like any other source: by its columns.
		final select = new SelectExpression(source);
		select.Selection = new ProjectionSqlExpression([
			for (column in columns) new ProjectionMember(column, new ColumnSqlExpression(source, column))
		]);
		return new SelectQueryImpl(select, context);
	}

	#if macro
	/** Whether a type is a value on its own — one column — rather than a row of them. */
	static function IsScalar(type:Type):Bool {
		return switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int" | "Float" | "Bool"}, _): true;
			case TInst(_.get() => {name: "String" | "Date"}, _): true;
			case _: false;
		}
	}

	/** A public instance variable is a column, as `ColumnsBuilder` has it. */
	static function IsColumn(field:ClassField):Bool {
		return field.isPublic && switch field.kind {
			case FVar(AccNormal | AccNo, _): true;
			case _: false;
		}
	}
	#end
}
