package codequery;

import codequery.sqlexpressions.*;

/**
	What a query knows about one of its rows while it runs: how to hand a lambda the row's columns,
	and how to read a fetched row back as the value the row type promises.

	The row types themselves live only on the `ISelectQueryN` a caller holds; the statement
	underneath is untyped. A clause compiled to a callback still has to be given something to name
	columns on, and `Fetch` has to build something to hand back — so each row carries one of these.
	An entity's comes from its generated columns type; a projection's is worked out from what it
	selected; a window's is the window itself.
**/
class RowShape {
	/** The object a lambda parameter at `index` receives: the row's columns, each an expression. */
	public final Columns:Int->Dynamic;

	/** A fetched row as the value the row stands for. */
	public final Read:Map<String, Dynamic>->Dynamic;

	public function new(columns:Int->Dynamic, read:Map<String, Dynamic>->Dynamic) {
		this.Columns = columns;
		this.Read = read;
	}

	/** The arguments a callback over `rows` is called with. */
	public static function Arguments(rows:Array<RowShape>):Array<Dynamic> {
		return [for (index => row in rows) row.Columns(index)];
	}

	/** A callback over `rows`, called with their columns. */
	public static function Call(callback:Dynamic, rows:Array<RowShape>):Dynamic {
		if (callback == null || !Reflect.isFunction(callback)) {
			throw "This clause takes a function over the query's rows; what it was given is not one";
		}
		return Reflect.callMethod(null, callback, Arguments(rows));
	}

	/**
		A row nothing described — a table constructed by hand rather than declared with
		`DbTable.of()` or named with `Query.table(T)`. Its columns cannot be handed to a lambda,
		and asking says so; its rows come back as the driver sent them.
	**/
	public static function Unshaped(what:String):RowShape {
		return new RowShape(_ -> throw 'The rows of $what have no shape here, so a lambda cannot be given their '
			+ 'columns. Declare the table with DbTable.of(), or name its entity with Query.table(T).',
			row -> row);
	}

	/** A window the query has defined, which a projection names to read an aggregate over it. */
	public static function Window(window:NamedWindowSqlSource):RowShape {
		return new RowShape(_ -> window, _ -> null);
	}

	/** One value with no name of its own — `Select(b -> b.id)`. Read back as the row's only column. */
	public static function Scalar(name:String, type:SqlType):RowShape {
		return new RowShape(index -> new ColumnSqlExpression(ParameterSqlSource.At(index), name, type), row -> {
			for (value in row) {
				return RowReader.As(value, type);
			}
			return null;
		});
	}

	/**
		A row built of named members, nested as the paths say: `{price: …, unit: {id: …}}`. Its
		columns are the members' names on the parameter's source; a fetched row is put back into
		the same nest, each value read by its member's type.
	**/
	public static function Structure(members:Array<ShapeMember>):RowShape {
		return new RowShape(index -> Nest(members,
			member -> new ColumnSqlExpression(ParameterSqlSource.At(index), member.name, member.type)),
			row -> Nest(members, member -> RowReader.As(row.get(member.name), member.type)));
	}

	/** The row a selection answers with, given the rows it was selected over. */
	public static function OfSelection(selection:ISqlExpression, rows:Array<RowShape>):RowShape {
		final all = Std.downcast(cast selection, AllColumnsSqlExpression);
		if (all != null) {
			final parameter = Std.downcast(cast all.Source, ParameterSqlSource);
			return parameter != null && parameter.Index < rows.length ? rows[parameter.Index] : Unshaped("this selection");
		}
		final projection = Std.downcast(cast selection, ProjectionSqlExpression);
		if (projection == null) {
			return Scalar("", RowReader.TypeOf(selection));
		}
		// One member naming nothing — an aggregate on its own — is one value, not a row of one.
		if (projection.Members.length == 1 && projection.Members[0].Path.length == 0) {
			return Scalar("", RowReader.TypeOf(projection.Members[0].Expression));
		}
		return Structure([
			for (member in projection.Members)
				{path: member.Path, name: member.Name, type: RowReader.TypeOf(member.Expression)}
		]);
	}

	/**
		The members nested as their paths say. Each object made carries its fields' order, since a
		projection selecting the row whole again spreads it in that order, and not every target keeps
		an object's fields in the order they were added.
	**/
	static function Nest(members:Array<ShapeMember>, value:ShapeMember->Dynamic):Dynamic {
		final root:Dynamic = RowProjection.Ordered([], {});
		for (member in members) {
			var at:Dynamic = root;
			for (step in 0...member.path.length - 1) {
				var next:Dynamic = Reflect.field(at, member.path[step]);
				if (next == null) {
					next = RowProjection.Ordered([], {});
					Reflect.setField(at, member.path[step], next);
					Order(at).push(member.path[step]);
				}
				at = next;
			}
			Reflect.setField(at, member.path[member.path.length - 1], value(member));
			Order(at).push(member.path[member.path.length - 1]);
		}
		return root;
	}

	static function Order(structure:Dynamic):Array<String> {
		return Reflect.field(structure, RowProjection.OrderField);
	}
}

/** One member of a structured row: where it sits, the column it comes back as, and its type. */
typedef ShapeMember = {
	final path:Array<String>;
	final name:String;
	final type:SqlType;
};
