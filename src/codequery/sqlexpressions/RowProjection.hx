package codequery.sqlexpressions;

/**
	What a `select` callback answered with, read as the statement's selection.

	A projection is written as a tree — `{price: b.price.zar, data: {id: b.id}, unit: u}` — and the
	callback a `Select` compiles to answers with that tree, its leaves expressions: an object built
	on the spot, a whole row's columns, or one expression standing alone. A result set is flat, so
	the tree is flattened here: every leaf becomes a column named along the column-name path that
	reaches it — `data_id`, `unit_name` — and keeps the field path, which is what lets a later
	clause name the leaf again.

	C# does this at runtime over an expression tree; the compile-time half of it is
	`ProjectionBuilder`, which shapes the tree and leaves the flattening to here.
**/
class RowProjection {
	/**
		The field a structure carries its members' order under, where the target's own field order
		cannot be relied on. `Ordered` sets it; a row a projection built always has it.
	**/
	public static inline final OrderField = "__members";

	/**
		The structure with its members' order written on it. A result set is ordered, and so is the
		structure as written — but not every target keeps an object's fields in the order they were
		written (eval orders them by name), so where it does not the order is carried along.
	**/
	public static function Ordered(members:Array<String>, structure:Dynamic):Dynamic {
		Reflect.setField(structure, OrderField, members);
		return structure;
	}

	/**
		The selection: an expression as itself, a whole row as all its columns, an object flattened
		into a row as those columns under their own names, a tree as a projection.
	**/
	public static function Selection(value:Dynamic):ISqlExpression {
		if (Std.isOfType(value, ISqlExpression)) {
			return value;
		}
		final row = Std.downcast(value, RowColumns);
		if (row != null && row.Prefix == "") {
			return new AllColumnsSqlExpression(row.Source);
		}
		return new ProjectionSqlExpression(Members(value));
	}

	/** The keys of a `GROUP BY` or a grouping set: one expression, or every member of a tree. */
	public static function Keys(value:Dynamic):Array<ISqlExpression> {
		if (Std.isOfType(value, ISqlExpression)) {
			return [value];
		}
		if (Std.isOfType(value, Array)) {
			final keys:Array<ISqlExpression> = [];
			for (item in (value : Array<Dynamic>)) {
				for (key in Keys(item)) {
					keys.push(key);
				}
			}
			return keys;
		}
		return Members(value).map(member -> member.Expression);
	}

	/** The tree flattened to its members, each named along the path that reaches it. */
	public static function Members(value:Dynamic):Array<ProjectionMember> {
		final into:Array<ProjectionMember> = [];
		Collect([], [], value, into);
		return into;
	}

	static function Collect(fields:Array<String>, columns:Array<String>, value:Dynamic, into:Array<ProjectionMember>):Void {
		if (value == null) {
			throw 'A projection selects expressions, and ${fields.join(".")} is null';
		}
		if (Std.isOfType(value, ISqlExpression)) {
			into.push(new ProjectionMember(columns.join(ProjectionMember.Separator), value, fields));
			return;
		}
		final row = Std.downcast(value, RowColumns);
		if (row != null) {
			for (member in row.Members()) {
				Collect(fields.concat([member.name]), columns.concat([member.column]), member.value, into);
			}
			return;
		}
		if (Std.isOfType(value, String) || !Reflect.isObject(value) || Reflect.isFunction(value)) {
			throw 'A projection selects expressions over the row, and ${fields.join(".")} is a value: ${Std.string(value)}';
		}
		for (name in FieldsOf(value)) {
			Collect(fields.concat([name]), columns.concat([name]), Reflect.field(value, name), into);
		}
	}

	/** A structure's fields, in the order it carries where it carries one, else the target's. */
	public static function FieldsOf(value:Dynamic):Array<String> {
		final ordered:Null<Array<String>> = Reflect.field(value, OrderField);
		if (ordered != null) {
			return ordered;
		}
		return Reflect.fields(value).filter(name -> name != OrderField);
	}
}
