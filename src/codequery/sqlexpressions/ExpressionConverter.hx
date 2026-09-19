package codequery.sqlexpressions;

import haxe.macro.Expr;
#if macro
import haxe.macro.Context;
import haxe.macro.Printer;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
#end

/**
	The Haxe stand-in for C#'s `Expression<SqlCondition<T1>>`.

	C# reifies the lambda into an `Expression` tree at runtime and converts it there. Haxe has no
	runtime expression trees, so the conversion happens during compilation: the lambda never becomes
	a closure, it becomes the code that builds the `ISqlExpression` tree the statement carries.

	A column resolves to a static member of the entity's generated columns type (see
	`ColumnsBuilder`), so what a predicate compiles to is a reference and not a column built afresh
	on each call. Nothing in it depends on the statement it lands in, so the whole condition is built
	where it is written — there is no closure.
**/
class ExpressionConverter {
	#if macro
	/**
		Convert a predicate lambda into an expression building its `ISqlExpression`.

		`entity` is the row type the lambda's parameter stands for; the predicate is typed against
		it so that an editor can see inside the lambda and so the body is type-checked.
	**/
	public static function Convert(predicate:Expr, rows:Array<Type>):Expr {
		return ConvertLambda(predicate, rows, macro :Bool, "a predicate, e.g. a -> a.id == 12");
	}

	/**
		Convert a key selector — `a -> a.id`, the `SqlKeySelector` of the C# API — into an
		expression building its `ISqlExpression`. Any expression will do, not only a column.
	**/
	public static function ConvertKey(selector:Expr, rows:Array<Type>):Expr {
		// The key is whatever the expression is; only the rows being typed matter here.
		return ConvertLambda(selector, rows, macro :Dynamic, "a key selector, e.g. a -> a.id");
	}

	static function ConvertLambda(lambda:Expr, rows:Array<Type>, returns:ComplexType, expected:String):Expr {
		TypeLambda(lambda, rows, returns);

		final fn = switch lambda.expr {
			case EFunction(_, f): f;
			case _: Context.error('Expected $expected', lambda.pos);
		}
		if (fn.args.length != rows.length) {
			Context.error('Expected $expected, taking ${rows.length} parameter${rows.length == 1 ? "" : "s"}',
				lambda.pos);
		}

		// Each parameter names a row, in the order the statement's sources are bound.
		final bound = new Map<String, Int>();
		for (index => arg in fn.args) {
			bound.set(arg.name, index);
		}
		return ToSqlExpression(fn.expr, bound, rows);
	}

	/**
		Type the lambda against the row it is written over and throw the result away.

		Nothing else types it — the tree is read as syntax — and Haxe answers completion, hover and
		go-to-definition while *typing* an expression. Without this an editor has nothing to offer
		inside the lambda. The typed expression is discarded, so none of it reaches the output.
	**/
	static function TypeLambda(lambda:Expr, rows:Array<Type>, returns:ComplexType):Void {
		final signature = ComplexType.TFunction([for (row in rows) row.toComplexType()], returns);
		Context.typeExpr(macro @:pos(lambda.pos) ($lambda : $signature));
	}

	/** Strip the syntax that carries no meaning for the conversion. */
	static function Unwrap(e:Expr):Expr {
		return switch e.expr {
			case EReturn(inner) if (inner != null): Unwrap(inner);
			case EParenthesis(inner): Unwrap(inner);
			case EMeta(_, inner): Unwrap(inner);
			case EBlock([inner]): Unwrap(inner);
			case _: e;
		}
	}

	/** Haxe syntax in, an expression that builds the SQL tree out. */
	static function ToSqlExpression(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final e = Unwrap(e);
		return switch e.expr {
			case EBinop(op, left, right):
				final factory = FactoryFor(op, e.pos);
				final l = ToSqlExpression(left, bound, rows);
				final r = ToSqlExpression(right, bound, rows);
				macro $factory($l, $r);

			case EField(_, _, _):
				final reached = PathOf(e, bound);
				if (reached == null) {
					// Not a column, so the only thing it can be is something with a value already —
					// an enum abstract's member, most often.
					final constant = ConstantOf(e);
					if (constant != null) {
						return constant;
					}
					Context.error('Only a column of a row this lambda is written over, or a constant, can be used here',
						e.pos);
				}
				final row = rows[reached.row];
				ColumnsBuilder.Member(ColumnsBuilder.Of(row, reached.row), MemberOf(reached.path, row, e.pos));

			case EConst(CInt(v, _)):
				macro ${Factory("constInt")}($v{Std.parseInt(v)});

			case EConst(CFloat(v, _)):
				macro ${Factory("constFloat")}($v{Std.parseFloat(v)});

			case EConst(CString(s, _)):
				macro ${Factory("constString")}($v{s});

			case EConst(CIdent("true")):
				macro ${Factory("constBool")}(true);

			case EConst(CIdent("false")):
				macro ${Factory("constBool")}(false);

			case EConst(CIdent("null")):
				macro ${Factory("constNull")}();

			// A negative literal is unary minus over a positive one, not a constant of its own.
			case EUnop(OpNeg, false, {expr: EConst(CInt(v, _))}):
				macro ${Factory("constInt")}($v{-Std.parseInt(v)});

			case _:
				final constant = ConstantOf(e);
				if (constant != null) {
					return constant;
				}
				Context.error('Cannot convert to SQL: ${e.toString()}', e.pos);
		}
	}

	/**
		The constant an expression already is, or null where it is not one.

		`BookingStatus.Confirmed` is the case this is for: an enum abstract's member is its value by
		the time it is typed, so asking the compiler what it is costs nothing and means SQL sees the
		number the database stores rather than a name it would not know.
	**/
	static function ConstantOf(e:Expr):Null<Expr> {
		final typed = try Context.typeExpr(e) catch (_:Dynamic) return null;
		return switch UnwrapTyped(typed).expr {
			case TConst(TInt(v)): macro ${Factory("constInt")}($v{v});
			case TConst(TFloat(v)): macro ${Factory("constFloat")}($v{Std.parseFloat(v)});
			case TConst(TString(v)): macro ${Factory("constString")}($v{v});
			case TConst(TBool(v)): macro ${Factory("constBool")}($v{v});
			case TConst(TNull): macro ${Factory("constNull")}();
			case _: null;
		}
	}

	/** An enum abstract's member arrives wrapped in the cast to its underlying type. */
	static function UnwrapTyped(e:TypedExpr):TypedExpr {
		return switch e.expr {
			case TCast(inner, _): UnwrapTyped(inner);
			case TMeta(_, inner): UnwrapTyped(inner);
			case TParenthesis(inner): UnwrapTyped(inner);
			case _: e;
		}
	}

	static function FactoryFor(op:Binop, pos:Position):Expr {
		return Factory(switch op {
			case OpEq: "equal";
			case OpNotEq: "notEqual";
			case OpLt: "lessThan";
			case OpLte: "lessThanOrEqual";
			case OpGt: "greaterThan";
			case OpGte: "greaterThanOrEqual";
			case OpBoolAnd: "and";
			case OpBoolOr: "or";
			case OpAdd: "add";
			case OpSub: "subtract";
			case OpMult: "multiply";
			case OpDiv: "divide";
			case OpMod: "modulo";
			case _: Context.error('Operator ${new Printer().printBinop(op)} has no SQL equivalent', pos);
		});
	}

	/** One of `Expr`'s factory methods, which is what a converted expression is built out of. */
	static function Factory(name:String):Expr {
		return macro $p{["codequery", "sqlexpressions", "Expr", name]};
	}

	/**
		The row a field access reaches, and the path of members to it — `b.price.zar` is row `b` and
		the path `[price, zar]`. Null where it does not start at a row this lambda is written over.
	**/
	static function PathOf(e:Expr, bound:Map<String, Int>):Null<{row:Int, path:Array<String>}> {
		final path:Array<String> = [];
		var walk = Unwrap(e);
		while (true) {
			switch walk.expr {
				case EField(owner, field, _):
					path.unshift(field);
					walk = Unwrap(owner);
				case EConst(CIdent(name)) if (bound.exists(name)):
					return {row: bound[name], path: path};
				case _:
					return null;
			}
		}
	}

	/**
		Checks that the row really has this path, so that a typo is a compile error here rather than
		a confusing one about the generated columns type. Answers with the name that type calls the
		member; the column it maps to is settled there.
	**/
	static function MemberOf(path:Array<String>, entity:Type, pos:Position):String {
		var row = switch entity.follow() {
			case TInst(t, _): t.get();
			case _: Context.error('${entity.toString()} is not a class, so it has no columns', pos);
		}

		for (step in 0...path.length) {
			final found = FieldNamed(row, path[step]);
			if (found == null) {
				final reached = step == 0 ? row.name : '${row.name} (reached by ${path.slice(0, step).join(".")})';
				Context.error('$reached has no field "${path[step]}"', pos);
			}
			if (step == path.length - 1) {
				break;
			}
			row = switch found.type.follow() {
				case TInst(t, _): t.get();
				case t: Context.error('${path[step]} is ${t.toString()}, which has no members to reach', pos);
			}
		}

		return path.join(ColumnsBuilder.Separator);
	}

	static function FieldNamed(row:ClassType, name:String):Null<ClassField> {
		for (field in row.fields.get()) {
			if (field.name == name) {
				return field;
			}
		}
		return null;
	}

	/**
		Convert a projection lambda — `a -> {store: a.fromStoreId, note: a.noteNo}`, the
		`SqlProjection` of the C# API — into the selection it describes and the row type it leaves.

		A lambda naming a row rather than building a structure — `(a, b) -> b`, which is what
		`Reduce` is for — selects that row's columns and keeps its type.
	**/
	public static function ConvertProjection(projection:Expr, rows:Array<Type>):{selection:Expr, row:Type} {
		final fn = switch projection.expr {
			case EFunction(_, f): f;
			case _: Context.error("Expected a projection, e.g. a -> {note: a.noteNo}", projection.pos);
		}
		if (fn.args.length != rows.length) {
			Context.error('Expected a projection taking ${rows.length} parameter${rows.length == 1 ? "" : "s"}',
				projection.pos);
		}

		final bound = new Map<String, Int>();
		for (index => arg in fn.args) {
			bound.set(arg.name, index);
		}

		// Typed first, and deliberately: the walk below only reads syntax, so if it ran first an
		// editor would get nothing back from inside the projection. Typing is what answers that.
		final row = ProjectedRow(fn, rows, projection.pos);
		return {selection: ToProjection(Unwrap(fn.expr), bound, rows), row: row};
	}

	/**
		The type a projection answers with, taken from the lambda itself: give its parameters the
		row types and the compiler works out the rest, which is also what lets an editor see inside.
	**/
	static function ProjectedRow(fn:Function, rows:Array<Type>, pos:Position):Type {
		final args:Array<FunctionArg> = [
			for (index => arg in fn.args) {name: arg.name, type: rows[index].toComplexType()}
		];
		final typed = {expr: EFunction(FAnonymous, {args: args, ret: null, expr: fn.expr}), pos: pos};
		return switch Context.typeof(typed).follow() {
			case TFun(_, ret): ret;
			case t: Context.error('A projection must answer with something; this one is ${t.toString()}', pos);
		}
	}

	static function ToProjection(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		return switch e.expr {
			// A structure names each member; the names are what the columns come back as.
			case EObjectDecl(fields):
				final members = {
					expr: EArrayDecl([
						for (field in fields) {
							final value = ToSqlExpression(field.expr, bound, rows);
							macro new codequery.sqlexpressions.ProjectionMember($v{field.field}, $value);
						}
					]),
					pos: e.pos
				};
				macro new codequery.sqlexpressions.ProjectionSqlExpression($members);

			// A row on its own selects that row's columns.
			case EConst(CIdent(name)) if (bound.exists(name)):
				final source = ColumnsBuilder.Member(ColumnsBuilder.Of(rows[bound[name]], bound[name]), "Source");
				macro new codequery.sqlexpressions.AllColumnsSqlExpression($source);

			case _:
				Context.error('A projection is a structure or a row, not ${e.toString()}', e.pos);
		}
	}

	/**
		Convert an aggregate projection — `a -> {rows: a.count(), biggest: a.max(r -> r.quantity)}`.

		The lambda's first parameter is the set of aggregates over the query's rows; a window the
		query has defined arrives as a further parameter, and an aggregate reads over it with
		`.over(w)`.
	**/
	public static function ConvertAggregation(projection:Expr, rows:Array<Type>, query:Expr):{selection:Expr, row:Type} {
		final fn = switch projection.expr {
			case EFunction(_, f): f;
			case _: Context.error("Expected an aggregate projection, e.g. a -> {rows: a.count()}", projection.pos);
		}

		// The aggregates stand in for the rows themselves, so the parameters are the set, then one
		// per window the query has picked up.
		final windows = rows.length - 1;
		if (fn.args.length != 1 + windows) {
			Context.error('Expected an aggregate projection taking ${1 + windows} parameter${windows == 0 ? "" : "s"}',
				projection.pos);
		}

		TypeAggregation(fn, rows, projection.pos);

		final bound = new Map<String, Int>();
		bound.set(fn.args[0].name, 0);
		final named = [for (index in 0...windows) fn.args[index + 1].name => index + 1];

		final members = switch Unwrap(fn.expr).expr {
			case EObjectDecl(fields): fields;
			case e: Context.error('An aggregate projection is a structure, not ${Unwrap(fn.expr).toString()}',
					projection.pos);
		}

		final built = {
			expr: EArrayDecl([
				for (field in members) {
					final value = ToAggregate(field.expr, fn.args[0].name, named, rows, query);
					macro new codequery.sqlexpressions.ProjectionMember($v{field.field}, $value);
				}
			]),
			pos: projection.pos
		};

		return {
			selection: macro new codequery.sqlexpressions.ProjectionSqlExpression($built),
			row: ProjectedRow(fn, AggregationRows(rows), projection.pos)
		};
	}

	/** The parameter types an aggregate projection is typed against. */
	static function AggregationRows(rows:Array<Type>):Array<Type> {
		final set = Context.getType("codequery.IAggregateSet");
		final window = Context.getType("codequery.INamedWindow");
		final typed = [switch set {
			case TInst(t, _): TInst(t, [rows[0]]);
			case t: t;
		}];
		for (_ in 1...rows.length) {
			typed.push(window);
		}
		return typed;
	}

	static function TypeAggregation(fn:Function, rows:Array<Type>, pos:Position):Void {
		final signature = ComplexType.TFunction([for (row in AggregationRows(rows)) row.toComplexType()], macro :Dynamic);
		final lambda = {expr: EFunction(FAnonymous, fn), pos: pos};
		Context.typeExpr(macro @:pos(pos) ($lambda : $signature));
	}

	/** One member of an aggregate projection: a call on the aggregate set, perhaps over a window. */
	static function ToAggregate(e:Expr, set:String, windows:Map<String, Int>, rows:Array<Type>, query:Expr):Expr {
		final e = Unwrap(e);
		return switch e.expr {
			// `<aggregate>.over(w)`
			case ECall({expr: EField({expr: inner}, "over", _)}, [window]):
				final named = switch Unwrap(window).expr {
					case EConst(CIdent(name)) if (windows.exists(name)): windows[name];
					case _: Context.error("over() takes a window this query has defined", window.pos);
				}
				final aggregate = ToAggregate({expr: inner, pos: e.pos}, set, windows, rows, query);
				macro $aggregate.Over(${WindowAt(query, named)});

			case ECall({expr: EField({expr: EConst(CIdent(name))}, fn, _)}, args) if (name == set):
				Aggregate(fn, args, rows, e.pos);

			case _:
				Context.error('An aggregate projection selects aggregates, not ${e.toString()}', e.pos);
		}
	}

	static function Aggregate(fn:String, args:Array<Expr>, rows:Array<Type>, pos:Position):Expr {
		final row = [rows[0]];
		final kind = macro $p{["codequery", "sqlexpressions", "AggregateType", AggregateNamed(fn, pos)]};

		if (fn == "count") {
			return macro new codequery.sqlexpressions.AggregateSqlExpression($kind);
		}
		final argument = ConvertKey(args[0], row);
		final distinct = fn == "countDistinct";
		return macro new codequery.sqlexpressions.AggregateSqlExpression($kind, $argument, $v{distinct});
	}

	static function AggregateNamed(fn:String, pos:Position):String {
		return switch fn {
			case "count" | "countDistinct": "Count";
			case "sum": "Sum";
			case "avg": "Avg";
			case "min": "Min";
			case "max": "Max";
			case _: Context.error('$fn is not an aggregate', pos);
		}
	}

	/** The window a statement holds at `index` among its sources, read back when the query runs. */
	static function WindowAt(query:Expr, index:Int):Expr {
		return macro codequery.queries.SelectQueryImpl.WindowOf($query, $v{index});
	}

	/**
		Convert a window spec — `w -> w.PartitionBy(a -> a.deliveryId).OrderBy(a -> a.id)` — into
		the partition keys and ordering terms it describes. The statement names it; a name is not
		something the spec carries.
	**/
	public static function ConvertWindow(spec:Expr, rows:Array<Type>):{partitionBy:Expr, orderBy:Expr} {
		final fn = switch spec.expr {
			case EFunction(_, f) if (f.args.length == 1): f;
			case _: Context.error("Expected a window spec, e.g. w -> w.PartitionBy(a -> a.id)", spec.pos);
		}

		final partitionBy:Array<Expr> = [];
		final orderBy:Array<Expr> = [];
		WalkWindow(Unwrap(fn.expr), fn.args[0].name, rows, partitionBy, orderBy);

		return {
			partitionBy: {expr: EArrayDecl(partitionBy), pos: spec.pos},
			orderBy: {expr: EArrayDecl(orderBy), pos: spec.pos}
		};
	}

	/** The chain is read from the outside in, so the terms are collected in the order written. */
	static function WalkWindow(e:Expr, spec:String, rows:Array<Type>, partitionBy:Array<Expr>, orderBy:Array<Expr>):Void {
		switch Unwrap(e).expr {
			case EConst(CIdent(name)) if (name == spec):
				return;

			case ECall({expr: EField(owner, call, _)}, args):
				WalkWindow(owner, spec, rows, partitionBy, orderBy);
				final key = ConvertKey(args[0], rows);
				switch call {
					case "PartitionBy":
						partitionBy.push(key);
					case "OrderBy" | "OrderByDesc":
						final ascending = call == "OrderBy";
						final nulls = args.length > 1
							? args[1]
							: macro codequery.sqlexpressions.NullsOrdering.Default;
						orderBy.push(macro new codequery.sqlexpressions.OrderByExpression($key, $v{ascending}, $nulls));
					case _:
						Context.error('A window is partitioned and ordered; $call is neither', e.pos);
				}

			case _:
				Context.error('Expected a window spec built on "$spec", not ${e.toString()}', e.pos);
		}
	}

	/**
		The column a `Set` is assigning to — a lambda naming one member of the row, and nothing else,
		since that is the only thing SQL can assign to.
	**/
	public static function ConvertColumn(selector:Expr, rows:Array<Type>):Expr {
		final converted = ConvertKey(selector, rows);
		return macro(${converted} : codequery.sqlexpressions.ColumnSqlExpression);
	}

	/**
		What a `Set` is assigning: a lambda is an expression over the row, and anything else is a
		value to be read where it stands.
	**/
	public static function ConvertValue(value:Expr, rows:Array<Type>):Expr {
		return switch value.expr {
			case EFunction(_, _): ConvertKey(value, rows);
			case _: Valued(value);
		}
	}

	/** A runtime value, as the constant it will be by the time the statement runs. */
	public static function Valued(value:Expr):Expr {
		// Unwrapped first: an enum abstract is its underlying number by the time SQL sees it, and
		// SqlDate is a date.
		final factory = Factory(switch Context.typeof(value).followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int"}, _): "constInt";
			case TAbstract(_.get() => {name: "Float"}, _): "constFloat";
			case TAbstract(_.get() => {name: "Bool"}, _): "constBool";
			case TInst(_.get() => {name: "String"}, _): "constString";
			case TInst(_.get() => {name: "Date"}, _): "constDate";
			case t: Context.error('${t.toString()} is not something a column can hold', value.pos);
		});
		return macro $factory($value);
	}

	/** An update or a delete answers with a query of its own kind, over the same row. */
	public static function AnsweringMutation(statement:Expr, self:Expr):Expr {
		final kind = switch Context.typeof(self).follow() {
			case TAbstract(t, rows): {name: t.get().name, rows: rows};
			case t: Context.error('Not an update or a delete: ${t.toString()}', self.pos);
		}
		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: kind.name,
			params: [for (row in kind.rows) TPType(row.toComplexType())]
		});
		return macro(cast $statement : $queryType);
	}

	/**
		An INSERT of one entity: a column and a read of the matching member, for every column the
		row has, nested members included.
	**/
	public static function ConvertInsert(table:Expr, entry:Expr, entity:Type):Expr {
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', entry.pos);
		}

		final columns:Array<Expr> = [];
		final values:Array<Expr> = [];
		InsertMembers(row, entry, [], [], columns, values);

		final columnList = {expr: EArrayDecl(columns), pos: entry.pos};
		final valueList = {expr: EArrayDecl(values), pos: entry.pos};
		return macro codequery.queries.InsertStatement.Of($table, $columnList, $valueList);
	}

	static function InsertMembers(row:ClassType, entry:Expr, member:Array<String>, visited:Array<String>,
			columns:Array<Expr>, values:Array<Expr>):Void {
		for (field in row.fields.get()) {
			if (!field.isPublic) {
				continue;
			}
			switch field.kind {
				case FVar(AccNormal | AccNo, _):
				case _: continue;
			}

			final name = field.name;
			final read = macro $entry.$name;
			final nested = switch field.type.follow() {
				case TInst(t, _):
					final held = t.get();
					final path = held.pack.concat([held.name]).join(".");
					(path == "String" || path == "Date") ? null : held;
				case _: null;
			}

			if (nested == null) {
				final column = member.concat([ColumnsBuilder.ColumnNameOf(field)]).join(ColumnsBuilder.Separator);
				columns.push(macro $v{column});
				values.push(Valued(read));
				continue;
			}

			final path = nested.pack.concat([nested.name]).join(".");
			if (visited.indexOf(path) >= 0) {
				Context.error('${row.name}.$name contains itself, so its columns have no end', entry.pos);
			}
			InsertMembers(nested, read, member.concat([ColumnsBuilder.ColumnNameOf(field)]),
				visited.concat([path]), columns, values);
		}
	}

	/** Whether an optional macro argument was left out at the call site. */
	public static function Omitted(arg:Null<Expr>):Bool {
		return arg == null || arg.expr.match(EConst(CIdent("null")));
	}

	/**
		A join: the source brings a row, the condition is written over every row the query then has,
		and which method is called depends on whether the source is a table or another query.
	**/
	public static function Join(self:Expr, source:Expr, on:Null<Expr>, joinType:String):Expr {
		final rows = EntitiesOf(self).concat([EntityOf(source)]);
		if (rows.length > MaxRows) {
			Context.error('A query can join up to $MaxRows rows, as in C#; this one would have ${rows.length}',
				source.pos);
		}

		final kind = macro $p{["codequery", "sqlexpressions", "JoinType", joinType]};
		final query = macro(cast $self : codequery.queries.SelectQueryImpl);
		final inner = macro(cast $source : codequery.queries.SelectQueryImpl);

		// A cross join has no condition, so it is left off rather than passed as null.
		final joined = if (on == null) {
			IsTable(source) ? macro $query.JoinTable($kind, $source) : macro $query.JoinQuery($kind, $inner);
		} else {
			final condition = Convert(on, rows);
			IsTable(source)
				? macro $query.JoinTable($kind, $source, $condition)
				: macro $query.JoinQuery($kind, $inner, $condition);
		}

		return Answering(joined, rows);
	}

	/** The row a window arrives as. */
	public static function WindowRow():Type {
		return Context.getType("codequery.INamedWindow");
	}

	/** As many rows as C# has an `ISelectQuery` for. */
	public static final MaxRows = 8;

	/**
		Give a statement back the row types it is over.

		Building a statement needs no generics — `SelectQueryImpl` does all of it — so a clause
		answers with one of those, and this puts it back into the `ISelectQueryN` for however many
		rows the query now has. The cast is safe by construction: the arity is counted here.
	**/
	public static function Answering(query:Expr, rows:Array<Type>):Expr {
		final name = "ISelectQuery" + (rows.length == 1 ? "" : Std.string(rows.length));
		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: name,
			params: [for (row in rows) TPType(row.toComplexType())]
		});
		return macro(cast $query : $queryType);
	}

	/** Whether the thing being joined in is a table rather than another query. */
	static function IsTable(source:Expr):Bool {
		return switch Context.typeof(source).follow() {
			case TInst(t, _): HasInterface(t.get(), "IQuery");
			case TAbstract(_, _): false;
			case _: false;
		}
	}

	static function HasInterface(row:ClassType, name:String):Bool {
		if (row.name == name) {
			return true;
		}
		for (implemented in row.interfaces) {
			if (HasInterface(implemented.t.get(), name)) {
				return true;
			}
		}
		return row.superClass != null && HasInterface(row.superClass.t.get(), name);
	}



	/** The row types a query is over, read from the static type of the query itself. */
	public static function EntitiesOf(query:Expr):Array<Type> {
		return switch Context.typeof(query).follow() {
			case TAbstract(_, rows) if (rows.length > 0): rows;
			case TInst(_, rows) if (rows.length > 0): rows;
			case t: Context.error('Cannot tell what rows this query is over: ${t.toString()}', query.pos);
		}
	}

	/** The row type behind an `IQuery<T>` or `ISelectQuery<T>` being joined in. */
	public static function EntityOf(source:Expr):Type {
		final rows = EntitiesOf(source);
		if (rows.length != 1) {
			Context.error('Expected a source of one row type, got ${rows.length}', source.pos);
		}
		return rows[0];
	}
	#end
}
