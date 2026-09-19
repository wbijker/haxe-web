package codequery.migrations;

import codequery.sqldrivers.SqlTranslator;

/**
	A view, as the schema describes it: its name, the query that defines it as SQL, and how a change
	to it is migrated. C# keeps the rendered `CREATE` as the routine's body; here the SELECT and the
	strategy are kept apart and the statement is rendered when a migration asks for it, so the one
	snapshot serves whichever dialect renders it — and a change to either is a change to the view.
**/
class DatabaseViewDefinition {
	public final Name:String;

	/** The query the view is defined by, rendered. */
	public final Select:String;

	public final Materialized:Bool;

	public final Strategy:DbMigrationStrategy;

	public function new(name:String, select:String, materialized:Bool = false, ?strategy:DbMigrationStrategy) {
		this.Name = name;
		this.Select = select;
		this.Materialized = materialized;
		this.Strategy = strategy == null ? CreateOrReplace : strategy;
	}

	/**
		The view a schema member declares, its definition rendered in the port's dialect. The
		strategy is the member's where it says one, else the view's own class's `@dbMigration` —
		read off the instance, since the member may be declared as a plain `DbView<T>`.
	**/
	public static function Of(view:DbView<Dynamic>, ?strategy:DbMigrationStrategy):DatabaseViewDefinition {
		if (strategy == null) {
			strategy = DeclaredOn(Type.getClass(view));
		}
		return new DatabaseViewDefinition(view.Table.Name, new SqlTranslator().ToSql(view.Defined()), false, strategy);
	}

	/** The `@dbMigration("<strategy>")` a view class carries, or null where it carries none. */
	static function DeclaredOn(cls:Class<Dynamic>):Null<DbMigrationStrategy> {
		if (cls == null) {
			return null;
		}
		final meta = haxe.rtti.Meta.getType(cls);
		final declared:Null<Array<Dynamic>> = meta == null ? null : Reflect.field(meta, "dbMigration");
		if (declared == null || declared.length == 0) {
			return DeclaredOn(Type.getSuperClass(cls));
		}
		return StrategyNamed(Std.string(declared[0]));
	}

	/** Whether two describe the same view, which is what a diff turns on. */
	public function Matches(other:DatabaseViewDefinition):Bool {
		return Name == other.Name
			&& Select == other.Select
			&& Materialized == other.Materialized
			&& Std.string(Strategy) == Std.string(other.Strategy);
	}

	/** A strategy by the name a snapshot writes it under. */
	public static function StrategyNamed(name:Null<String>):DbMigrationStrategy {
		if (name == null) {
			return CreateOrReplace;
		}
		return switch name {
			case "DropThenCreate": DropThenCreate;
			case "DropCascadeThenCreate": DropCascadeThenCreate;
			case "DropCascadeThenRestore": DropCascadeThenRestore;
			case "CreateIfAbsent": CreateIfAbsent;
			case "RenameSwap": RenameSwap;
			case _: CreateOrReplace;
		}
	}
}
