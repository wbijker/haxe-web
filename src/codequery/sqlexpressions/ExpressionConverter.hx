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

	The lambda is converted in one of two shapes. As a *callback* — what `Where`, `Select`,
	`OrderBy` and the rest compile to — it stays a function, its parameters now the rows' columns
	(see `ColumnsBuilder`) and its body the code building the tree: `b -> b.price.zar > 100` becomes
	`(b:BookingColumns) -> Expr.greaterThan(b.price.zar, Expr.constInt(100))`, and the query calls it
	with the columns of each row it is over. *Inline*, the tree is built where the lambda was
	written, and a column names its source by the position of the parameter it was reached through
	— the shape a subquery's reach into the row outside takes, and an aggregate's selector.
**/
@:allow(codequery.sqlexpressions.ProjectionBuilder)
class ExpressionConverter {
	#if macro
	/**
		The callback being converted, where one is: the names its parameters have, by row. Null
		while converting inline, when a column is built on its parameter's position instead.
	**/
	static var callback:Null<{names:Array<String>}>;

	/** The callback parameter standing for row `index`, or null where the conversion is inline. */
	public static function CallbackName(index:Int):Null<String> {
		return callback == null ? null : callback.names[index];
	}

	/**
		Convert a predicate lambda into an expression building its `ISqlExpression`.

		`entity` is the row type the lambda's parameter stands for; the predicate is typed against
		it so that an editor can see inside the lambda and so the body is type-checked.
	**/
	public static function Convert(predicate:Expr, rows:Array<Type>):Expr {
		return ConvertLambda(predicate, rows, macro :Bool, "a predicate, e.g. a -> a.id == 12");
	}

	/** The same predicate as a callback over the rows' columns, which is what `where` is handed. */
	public static function ConvertCallback(predicate:Expr, rows:Array<Type>):Expr {
		return ConvertLambda(predicate, rows, macro :Bool, "a predicate, e.g. a -> a.id == 12", true);
	}

	/**
		Convert a key selector — `a -> a.id`, the `SqlKeySelector` of the C# API — into an
		expression building its `ISqlExpression`. Any expression will do, not only a column.
	**/
	public static function ConvertKey(selector:Expr, rows:Array<Type>):Expr {
		// The key is whatever the expression is; only the rows being typed matter here.
		return ConvertLambda(selector, rows, macro :Dynamic, "a key selector, e.g. a -> a.id");
	}

	/** The same key selector as a callback over the rows' columns. */
	public static function ConvertKeyCallback(selector:Expr, rows:Array<Type>):Expr {
		return ConvertLambda(selector, rows, macro :Dynamic, "a key selector, e.g. a -> a.id", true);
	}

	static function ConvertLambda(given:Expr, rows:Array<Type>, returns:ComplexType, expected:String, asCallback:Bool = false):Expr {
		final lambda = ResolveLambda(given);

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

		// A subquery the body writes has the outer row's columns put in before anything is typed.
		final body = LambdaCalls.PrepareSubqueries(fn.expr, bound, rows);
		TypeLambda({expr: EFunction(FAnonymous, {args: fn.args, ret: fn.ret, expr: body}), pos: lambda.pos}, rows, returns);

		final names = [for (arg in fn.args) arg.name];
		final converted = Converting(asCallback ? names : null, () -> ToSqlExpression(body, bound, rows));
		return asCallback ? Callback(names, rows, converted, lambda.pos) : converted;
	}

	/** Runs a conversion as a callback over the named parameters, or inline where there are none. */
	static function Converting<T>(names:Null<Array<String>>, convert:() -> T):T {
		final enclosing = callback;
		callback = names == null ? null : {names: names};
		final converted = try convert() catch (failed:Dynamic) {
			callback = enclosing;
			throw failed;
		}
		callback = enclosing;
		return converted;
	}

	/**
		The callback a converted body becomes: a function of the rows' columns, one parameter per
		row under the name the lambda gave it, answering with the tree the body builds.
	**/
	public static function Callback(names:Array<String>, rows:Array<Type>, body:Expr, pos:Position):Expr {
		final args:Array<FunctionArg> = [for (index => name in names) {name: name, type: ColumnsTypeOf(rows[index])}];
		return {
			expr: EFunction(FAnonymous, {args: args, ret: null, expr: {expr: EReturn(body), pos: pos}}),
			pos: pos
		};
	}

	/**
		What a callback's parameter is for a row: an entity's generated columns type, a structure of
		columns for a row a projection built, the window itself for a window, the one column for a
		value.
	**/
	public static function ColumnsTypeOf(row:Type):ComplexType {
		if (IsWindowRow(row)) {
			return macro :codequery.sqlexpressions.NamedWindowSqlSource;
		}
		return switch row.follow() {
			case TInst(_, _) if (ProjectionBuilder.IsObject(row)): ColumnsBuilder.TypeOf(row);
			case TAnonymous(_): MemberColumnsType(row, []);
			case _: macro :codequery.sqlexpressions.ColumnSqlExpression;
		}
	}

	/** The columns a member holding a row is handed as: a structure of its fields' columns, however deep. */
	static function MemberColumnsType(type:Type, visited:Array<String>):ComplexType {
		if (!ProjectionBuilder.IsObject(type)) {
			return macro :codequery.sqlexpressions.ColumnSqlExpression;
		}
		final name = type.toString();
		if (visited.indexOf(name) >= 0) {
			return macro :Dynamic;
		}
		final fields:Array<Field> = [];
		final anonymous = IsStructure(type);
		for (field in FieldsOf(type)) {
			if (!anonymous && !ColumnsBuilder.IsColumn(field)) {
				continue;
			}
			fields.push({
				name: field.name,
				pos: field.pos,
				access: [],
				kind: FVar(MemberColumnsType(field.type, visited.concat([name])))
			});
		}
		return TAnonymous(fields);
	}

	/**
		How a query hands a lambda the columns of a row of this type, and reads a row back as it:
		an entity's is its columns type's; a structure's is built from its members; a value's is
		the one column.
	**/
	public static function ShapeOf(row:Type):Expr {
		if (IsWindowRow(row)) {
			return macro codequery.RowShape.Unshaped("a window");
		}
		return switch row.follow() {
			case TInst(_, _) if (ProjectionBuilder.IsObject(row)):
				ColumnsBuilder.ShapeOf(row);
			case TAnonymous(_):
				final members = [
					for (leaf in ProjectionBuilder.Leaves(row, [], []))
						macro {
							path: $a{leaf.fields.map(step -> macro $v{step})},
							name: $v{leaf.names.join(ColumnsBuilder.Separator)},
							type: ${ColumnsBuilder.SqlTypeOfType(leaf.type)}
						}
				];
				macro codequery.RowShape.Structure($a{members});
			case _:
				macro codequery.RowShape.Scalar("", ${ColumnsBuilder.SqlTypeOfType(row)});
		}
	}

	/** The `SqlType` a value of a Haxe type is. */
	public static function SqlTypeExprOf(type:Type):Expr {
		return ColumnsBuilder.SqlTypeOfType(type);
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

	/**
		The lambda an argument stands for.

		Usually it is written where it is used. It may instead name a function that answers with one
		— which is how an entity declares a join it is always made by, as C#'s `Booking.WithUnit`
		does: the function is read back and its lambda used as if it had been written out.
	**/
	static function ResolveLambda(e:Expr):Expr {
		final e = Unwrap(e);
		if (e.expr.match(EFunction(_, _))) {
			return e;
		}

		final declared = try Context.typeExpr(e) catch (_:Dynamic) return e;
		final called = switch declared.expr {
			case TField(_, FStatic(_, cf)): {field: cf.get(), args: []};
			// Called with values — `Booking.WithNamedUnit(wanted)` — the lambda it answers with
			// is read with the function's parameters standing for what was passed.
			case TCall({expr: TField(_, FStatic(_, cf))}, args): {field: cf.get(), args: args.map(Context.getTypedExpr)};
			case _: return e;
		}

		final body = called.field.expr();
		if (body == null) {
			return e;
		}
		// The function answers with the lambda, so what is wanted is what it returns, with what was
		// passed put in for its parameters — unless the static holds the lambda itself, in which
		// case that is what is wanted.
		final held = Unwrap(Context.getTypedExpr(body));
		return switch held.expr {
			case EFunction(_, {args: parameters, expr: answered}):
				final passed = new Map<String, Expr>();
				for (index => parameter in parameters) {
					if (index < called.args.length) {
						passed.set(parameter.name, called.args[index]);
					}
				}
				final returned = Returned(Unwrap(answered));
				returned.expr.match(EFunction(_, _)) ? Substitute(returned, passed) : held;
			case _: e;
		}
	}

	/** The expression with each named identifier replaced by what stands for it. */
	static function Substitute(e:Expr, passed:Map<String, Expr>):Expr {
		if (!passed.keys().hasNext()) {
			return e;
		}
		return switch e.expr {
			case EConst(CIdent(name)) if (passed.exists(name)): passed.get(name);
			case _: ExprTools.map(e, inner -> Substitute(inner, passed));
		}
	}

	/** The expression a body answers with. */
	static function Returned(e:Expr):Expr {
		return switch e.expr {
			case EReturn(inner) if (inner != null): Unwrap(inner);
			case EBlock(exprs) if (exprs.length > 0): Returned(Unwrap(exprs[exprs.length - 1]));
			case _: e;
		}
	}

	/** Strip the syntax that carries no meaning for the conversion. */
	static function Unwrap(e:Expr):Expr {
		return switch e.expr {
			case EReturn(inner) if (inner != null): Unwrap(inner);
			case EParenthesis(inner): Unwrap(inner);
			// A cast's target type is named by annotating it, which is not part of the expression.
			case ECheckType(inner, _): Unwrap(inner);
			case EMeta(_, inner): Unwrap(inner);
			case EBlock([inner]): Unwrap(inner);
			case _: e;
		}
	}

	/** Haxe syntax in, an expression that builds the SQL tree out. */
	static function ToSqlExpression(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final e = Unwrap(e);
		// A method on something in the lambda — a captured list tested, a query asked a question,
		// a row's string searched — is read before anything else claims the call.
		switch e.expr {
			case ECall({expr: EField(owner, method, _)}, args):
				final special = LambdaCalls.MethodCall(e, owner, method, args, bound, rows);
				if (special != null) {
					return special;
				}
			case _:
		}
		// A call of a string's or a date's methods, a span, an inline function: read there next.
		final extended = FunctionConverter.Convert(e, bound, rows);
		if (extended != null) {
			return extended;
		}
		return switch e.expr {
			case EBinop(op, left, right):
				final quantified = Quantified(op, left, right, bound, rows, e.pos);
				if (quantified != null) {
					return quantified;
				}
				final special = LambdaCalls.Binary(op, left, right, bound, rows);
				if (special != null) {
					return special;
				}
				final factory = FactoryFor(op, e.pos);
				final l = ToSqlExpression(left, bound, rows);
				final r = ToSqlExpression(right, bound, rows);
				macro $factory($l, $r);

			// Haxe says CASE WHEN with a ternary, so that is what it converts to.
			case ETernary(condition, then, otherwise) | EIf(condition, then, otherwise) if (otherwise != null):
				final branch = macro codequery.sqlexpressions.Expr.branch(
					${ToSqlExpression(condition, bound, rows)}, ${ToSqlExpression(then, bound, rows)});
				final fallback = ToSqlExpression(otherwise, bound, rows);
				macro codequery.sqlexpressions.Expr.caseWhen([$branch], $fallback);

			case EUnop(OpNot, false, operand):
				LambdaCalls.Negation(ToSqlExpression(operand, bound, rows));

			// `cast(x, Int)` is `CAST(x AS INTEGER)` — the one place a Haxe cast has SQL to say.
			case ECast(inner, type) if (type != null):
				final target = SqlTypeOf(Context.resolveType(type, e.pos), e.pos);
				macro codequery.sqlexpressions.Expr.castTo(${ToSqlExpression(inner, bound, rows)}, $target);
			// Inside a HAVING, a call on the aggregate set — `a.count()`, `a.key(r -> r.id)`.
			case ECall(_, _) if (aggregateScope != null && IsAggregateCall(e, aggregateScope.set)):
				ToAggregate(e, aggregateScope.set, aggregateScope.windows, aggregateScope.entities, aggregateScope.query);

			// The calls of `Sql`, which is where what SQL has and Haxe has not is written.
			case ECall({expr: EField({expr: EConst(CIdent("Sql"))}, name, _)}, args)
				| ECall({expr: EField({expr: EField({expr: EConst(CIdent("codequery"))}, "Sql", _)}, name, _)}, args):
				SqlCall(name, args, bound, rows, e.pos);

			// `Std.string(x)` is `CAST(x AS TEXT)`, as C#'s `x.ToString()` is.
			case ECall({expr: EField({expr: EConst(CIdent("Std"))}, "string", _)}, [value]):
				macro codequery.sqlexpressions.Expr.castTo(${ToSqlExpression(value, bound, rows)},
					codequery.sqlexpressions.SqlType.SqlText);
			// `DbCase.When(…).Else(…)` — CASE written out rather than as a ternary.
			case ECall(_, _) if (LambdaCalls.IsCaseChain(e)):
				LambdaCalls.CaseChain(e, bound, rows);

			// A method on something in the lambda: a row's string searched, a query asked a
			// question, a captured list tested — or a call over captured values, which is a value.
			case ECall({expr: EField(owner, method, _)}, args):
				final special = LambdaCalls.MethodCall(e, owner, method, args, bound, rows);
				special != null ? special : Otherwise(e, bound, rows);

			case EField(_, _, _):
				final reached = PathOf(e, bound);
				if (reached == null) {
					// Not a column, so the only thing it can be is something with a value already —
					// an enum abstract's member, most often, or a value the lambda closed over.
					final constant = ConstantOf(e);
					if (constant != null) {
						return constant;
					}
					final captured = Captured(e);
					if (captured != null) {
						return captured;
					}
					Context.error('Only a column of a row this lambda is written over, or a constant, can be used here',
						e.pos);
				}
				ColumnFor(rows[reached.row], reached.row, reached.path, e.pos);

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
				Otherwise(e, bound, rows);
		}
	}

	/**
		What is left for an expression no case above claims: an aggregate or window function read
		beside the row's columns, an expression already built, a constant, or a value the lambda
		closed over — in that order, since each is narrower than the next.
	**/
	static function Otherwise(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final windowed = WindowConverter.Convert(e, bound, rows, x -> ToSqlExpression(x, bound, rows));
		if (windowed != null) {
			return windowed;
		}
		// Already an expression — a lateral's inner query is handed the outer row's columns this
		// way, since it has no parameter of its own for them.
		if (IsSqlExpression(e)) {
			return e;
		}
		final constant = ConstantOf(e);
		if (constant != null) {
			return constant;
		}
		final captured = Captured(e);
		if (captured != null) {
			return captured;
		}
		return LambdaCalls.Captured(e);
	}

	/** What is left when the syntax says nothing: an expression already, a constant, or a captured value. */
	static function Fallback(e:Expr):Expr {
		// Already an expression — a lateral's inner query is handed the outer row's
		// columns this way, since it has no parameter of its own for them.
		if (IsSqlExpression(e)) {
			return e;
		}
		final constant = ConstantOf(e);
		if (constant != null) {
			return constant;
		}
		return LambdaCalls.Captured(e);
	}

	/**
		An expression that is a value rather than a column — a captured local, a static, a member of
		one — as the constant it will be when the statement is built; null where it is not one a
		column could hold, or cannot be typed here at all.
	**/
	static function ValueOf(e:Expr):Null<Expr> {
		final type = try Context.typeof(e) catch (_:Dynamic) return null;
		return switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int" | "Float" | "Bool"}, _): ValuedAs(e, type);
			case TInst(_.get() => {name: "String" | "Date"}, _): ValuedAs(e, type);
			case _: null;
		}
	}

	/**
		A value the lambda closed over — a local, a field, a call — sent beside the statement as
		a parameter, which is what C# does with a captured variable. Null where the expression is
		not something a parameter can hold, or cannot be typed here at all.
	**/
	static function Captured(e:Expr):Null<Expr> {
		final type = try Context.typeof(e) catch (_:Dynamic) return null;
		return switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int" | "Float" | "Bool"}, _)
				| TInst(_.get() => {name: "String" | "Date"}, _):
				ParameterisedAs(e, type);
			case _:
				null;
		}
	}

	/** Whether a call chain starts at the aggregate set — `a.count()`, `a.sum(…).filter(…)`. */
	static function IsAggregateCall(e:Expr, set:String):Bool {
		return switch Unwrap(e).expr {
			case ECall({expr: EField(owner, _, _)}, _):
				switch Unwrap(owner).expr {
					case EConst(CIdent(name)): name == set;
					case _: IsAggregateCall(owner, set);
				}
			case _:
				false;
		}
	}

	/** The HAVING being converted, where a call on its aggregate set is an aggregate. */
	static var aggregateScope:Null<{set:String, windows:Map<String, Int>, entities:Array<Type>, query:Expr}>;

	/**
		Convert a predicate over the aggregates — `a -> a.count() > 5`, which is what `Having`
		takes — into an expression building its `ISqlExpression`. The lambda's first parameter is
		the aggregate set, as in `SelectAggregation`; a window the query defined follows it.
	**/
	public static function ConvertAggregatePredicate(predicate:Expr, rows:Array<Type>, query:Expr):Expr {
		final fn = switch predicate.expr {
			case EFunction(_, f): f;
			case _: Context.error("Expected a predicate over the aggregates, e.g. a -> a.count() > 5", predicate.pos);
		}
		final entities = EntityRows(rows);
		final windows = rows.length - entities.length;
		if (fn.args.length != 1 + windows) {
			Context.error('Expected a predicate taking ${1 + windows} parameter${windows == 0 ? "" : "s"}', predicate.pos);
		}
		TypeAggregation(fn, rows, predicate.pos);

		final named = [for (index in 0...windows) fn.args[index + 1].name => entities.length + index];
		final previous = aggregateScope;
		aggregateScope = {set: fn.args[0].name, windows: named, entities: entities, query: query};
		final converted = Converting(null, () -> ToSqlExpression(Unwrap(fn.expr), new Map(), entities));
		aggregateScope = previous;
		return converted;
	}

	/** The rows of a query that are rows, leaving aside the windows it has defined. */
	static function EntityRows(rows:Array<Type>):Array<Type> {
		return rows.filter(row -> !IsWindowRow(row));
	}

	static function IsWindowRow(row:Type):Bool {
		return switch row.follow() {
			case TInst(t, _): t.get().name == "INamedWindow";
			case _: false;
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

	/** Whether an expression is already one of ours, and so needs no converting. */
	static function IsSqlExpression(e:Expr):Bool {
		return try {
			Context.unify(Context.typeof(e), Context.getType("codequery.sqlexpressions.ISqlExpression"));
		} catch (_:Dynamic) {
			false;
		}
	}

	/**
		A lateral join: the inner query is written against the outer row, and joined to it.

		Everything else takes a lambda over rows and converts it. A lateral takes a lambda that
		answers with a whole query, and that query is built by its own macro calls — which bind
		their parameters from zero in their own statement, knowing nothing of the row outside. So
		the outer row's columns are substituted into the body before any of that runs, each one
		marked as belonging a statement further out.
	**/
	public static function Lateral(self:Expr, lateral:Expr, joinType:String):Expr {
		final rows = EntitiesOf(self);
		final fn = switch lateral.expr {
			case EFunction(_, f) if (f.args.length == rows.length): f;
			case _: Context.error('Expected a lambda of ${rows.length} row(s) answering with a query',
					lateral.pos);
		}

		final bound = new Map<String, Int>();
		for (index => arg in fn.args) {
			bound.set(arg.name, index);
		}

		// Substituted before anything is typed: typing the body expands the inner query's own
		// macros, and they must see the outer row's columns already put in.
		final inner = SubstituteOuter(Unwrap(fn.expr), bound, rows);

		final kind = macro $p{["codequery", "sqlexpressions", "JoinType", joinType]};
		final query = macro(cast $self : codequery.queries.SelectQueryImpl);
		final joined = macro $query.JoinQuery($kind, (cast $inner : codequery.queries.SelectQueryImpl));

		// The joined query brings a row, as any other join does.
		return Answering(joined, rows.concat([LateralRow(inner, lateral.pos)]));
	}

	/** The row a lateral's query answers with. */
	static function LateralRow(inner:Expr, pos:Position):Type {
		return switch Context.typeof(inner).follow() {
			case TAbstract(_, [row]): row;
			case TInst(_, [row]): row;
			case t: Context.error('A lateral answers with a query; this one answers with ${t.toString()}', pos);
		}
	}

	/** Replace every reach into an outer row with that column, marked a statement further out. */
	static function SubstituteOuter(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		return switch e.expr {
			case EField(_, _, _):
				final reached = PathOf(e, bound);
				if (reached == null) {
					{expr: ExprTools.map(e, inner -> SubstituteOuter(inner, bound, rows)).expr, pos: e.pos};
				} else {
					final row = rows[reached.row];
					// Built on the parameter's position rather than reached through the parameter:
					// the inner query is converted on its own, where the outer parameter is not in scope.
					final column = InlineColumn(row, reached.row, reached.path, e.pos);
					// Annotated with what the member holds, so the inner query still type-checks —
					// a predicate is typed before it is read, and a column is not an Int.
					final held = MemberTypeOf(reached.path, row, e.pos).toComplexType();
					macro(cast codequery.sqlexpressions.Expr.outer($column) : $held);
				}

			case _:
				ExprTools.map(e, inner -> SubstituteOuter(inner, bound, rows));
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

	/**
		`x > ANY (…)` and `x = ALL (…)`, which read as a comparison against `Sql.any` or `Sql.all` —
		so the operator belongs to the comparison and the quantifier to the side it is against.
	**/
	static function Quantified(op:Binop, left:Expr, right:Expr, bound:Map<String, Int>, rows:Array<Type>,
			pos:Position):Null<Expr> {
		// The quantifier is always the right-hand side; written on the left, the operator turns
		// round with it: `Sql.all(q) < x` is `x > ALL (q)`.
		var quantifier = QuantifierOf(right);
		var value = left;
		var comparison = op;
		if (quantifier == null) {
			quantifier = QuantifierOf(left);
			value = right;
			comparison = Flipped(op);
		}
		if (quantifier == null) {
			return null;
		}

		final comparator = OperatorFor(comparison, pos);
		final name = quantifier.name;
		final subquery = Statement(quantifier.query);
		return macro codequery.sqlexpressions.Expr.quantified(${ToSqlExpression(value, bound, rows)}, $comparator,
			$p{["codequery", "sqlexpressions", "Quantifier", name]}, $subquery);
	}

	/** `Sql.any(q)`, `Sql.all(q)` or `Sql.some(q)` — a synonym for any — and the query it quantifies. */
	static function QuantifierOf(e:Expr):Null<{name:String, query:Expr}> {
		return switch Unwrap(e).expr {
			case ECall({expr: EField({expr: EConst(CIdent("Sql"))}, name, _)}, [query])
				| ECall({expr: EField({expr: EField({expr: EConst(CIdent("codequery"))}, "Sql", _)}, name, _)}, [query])
				if (name == "any" || name == "all" || name == "some"):
				{name: name == "all" ? "All" : "Any", query: query};
			case _: null;
		}
	}

	/** The operator with its sides swapped: `<` becomes `>`, `<=` becomes `>=`, and equality stays. */
	static function Flipped(op:Binop):Binop {
		return switch op {
			case OpLt: OpGt;
			case OpLte: OpGte;
			case OpGt: OpLt;
			case OpGte: OpLte;
			case _: op;
		}
	}

	/** The `SqlBinaryOperator` an operator maps to, which a quantified comparison needs by name. */
	static function OperatorFor(op:Binop, pos:Position):Expr {
		final name = switch op {
			case OpEq: "Equal";
			case OpNotEq: "NotEqual";
			case OpLt: "LessThan";
			case OpLte: "LessThanOrEqual";
			case OpGt: "GreaterThan";
			case OpGte: "GreaterThanOrEqual";
			case _: Context.error('Operator ${new Printer().printBinop(op)} cannot be quantified', pos);
		}
		return macro $p{["codequery", "sqlexpressions", "SqlBinaryOperator", name]};
	}

	/** One of `Sql`'s calls, as the expression it stands for. */
	static function SqlCall(name:String, args:Array<Expr>, bound:Map<String, Int>, rows:Array<Type>, pos:Position):Expr {
		// Converted only where a call actually wants it: `isIn` takes its values as a list, which is
		// not an expression and would not convert.
		final arg = (index:Int) -> ToSqlExpression(args[index], bound, rows);
		final list = (from:Int) -> {
			expr: EArrayDecl([for (index in from...args.length) arg(index)]),
			pos: pos
		};

		return switch name {
			case "isIn" | "notIn":
				final negate = name == "notIn";
				Membership(args[0], args[1], negate, bound, rows, pos);

			case "inBound" | "notInBound":
				Membership(args[0], args[1], name == "notInBound", bound, rows, pos, true);

			case "exists" | "notExists":
				final negate = name == "notExists";
				macro codequery.sqlexpressions.Expr.exists(${Statement(args[0])}, $v{negate});

			case "row":
				macro codequery.sqlexpressions.Expr.row(${list(0)});

			case "likeAll":
				LambdaCalls.LikeAll(args[0], args[1], bound, rows, pos);

			case "inQuery" | "notInQuery":
				final negate = name == "notInQuery";
				macro codequery.sqlexpressions.Expr.inQuery(${arg(0)}, ${Statement(args[1])}, $v{negate});

			case "between" | "notBetween":
				final negate = name == "notBetween";
				macro codequery.sqlexpressions.Expr.between(${arg(0)}, ${arg(1)}, ${arg(2)}, $v{negate});

			case "like" | "notLike" | "ilike" | "notIlike":
				final matching = StringTools.endsWith(name.toLowerCase(), "ilike") ? "ILIKE" : "LIKE";
				// The escape character is stated rather than assumed: `x LIKE p ESCAPE e`.
				final pattern = args.length > 2
					? macro codequery.sqlexpressions.Expr.infix("ESCAPE", [${arg(1)}, ${arg(2)}])
					: arg(1);
				final comparison = macro codequery.sqlexpressions.Expr.infix($v{matching}, [${arg(0)}, $pattern]);
				StringTools.startsWith(name, "not") ? macro codequery.sqlexpressions.Expr.not($comparison) : comparison;

			case "isDistinctFrom" | "isNotDistinctFrom":
				final negate = name == "isNotDistinctFrom";
				macro codequery.sqlexpressions.Expr.isDistinctFrom(${arg(0)}, ${arg(1)}, $v{negate});

			case "castTo":
				macro codequery.sqlexpressions.Expr.castTo(${arg(0)}, ${args[1]});

			case "raw":
				macro codequery.sqlexpressions.Expr.raw(${args[0]});

			case "param":
				Parameterised(args[0]);

			case "scalar" | "correlated":
				final correlated = name == "correlated";
				macro codequery.sqlexpressions.Expr.scalar(${Statement(args[0])}, $v{correlated});

			case "comment":
				macro new codequery.sqlexpressions.SqlCommentExpression(${arg(0)}, ${args[1]});

			// `any` and `all` stand on one side of a comparison, so the operator is picked up there.
			case "any" | "all":
				Context.error('Sql.$name belongs on one side of a comparison, e.g. a.id == Sql.any(q)', pos);

			// EXTRACT takes one argument written as `part FROM value`, not two.
			case "datePart":
				macro codequery.sqlexpressions.Expr.call("EXTRACT", [
					codequery.sqlexpressions.Expr.infix("FROM", [codequery.sqlexpressions.Expr.raw(${args[0]}), ${arg(1)}])
				]);

			case "dateAdd" | "dateSubtract":
				final sign = name == "dateAdd" ? "+" : "-";
				macro codequery.sqlexpressions.Expr.infix($v{sign}, [${arg(0)}, ${Interval(args[1], args[2])}]);

			case "abs": macro codequery.sqlexpressions.Expr.call("ABS", ${list(0)});
			case "round": macro codequery.sqlexpressions.Expr.call("ROUND", ${list(0)});
			case "ceil": macro codequery.sqlexpressions.Expr.call("CEIL", ${list(0)});
			case "floor": macro codequery.sqlexpressions.Expr.call("FLOOR", ${list(0)});
			case "sign": macro codequery.sqlexpressions.Expr.call("SIGN", ${list(0)});
			case "power": macro codequery.sqlexpressions.Expr.call("POWER", ${list(0)});
			case "sqrt": macro codequery.sqlexpressions.Expr.call("SQRT", ${list(0)});
			case "exp": macro codequery.sqlexpressions.Expr.call("EXP", ${list(0)});
			case "ln": macro codequery.sqlexpressions.Expr.call("LN", ${list(0)});
			case "log": macro codequery.sqlexpressions.Expr.call("LOG", ${list(0)});
			case "greatest": macro codequery.sqlexpressions.Expr.call("GREATEST", ${list(0)});
			case "least": macro codequery.sqlexpressions.Expr.call("LEAST", ${list(0)});
			case "left": macro codequery.sqlexpressions.Expr.call("LEFT", ${list(0)});
			case "right": macro codequery.sqlexpressions.Expr.call("RIGHT", ${list(0)});
			case "random": macro codequery.sqlexpressions.Expr.call("RANDOM", ${list(0)});
			case "now": macro codequery.sqlexpressions.Expr.call("NOW", ${list(0)});

			// The ordered-set aggregates: `f(…) WITHIN GROUP (ORDER BY x)`.
			case "percentileCont": macro codequery.sqlexpressions.Expr.withinGroup("percentile_cont", [${arg(0)}], ${arg(1)});
			case "percentileDisc": macro codequery.sqlexpressions.Expr.withinGroup("percentile_disc", [${arg(0)}], ${arg(1)});
			case "median": macro codequery.sqlexpressions.Expr.withinGroup("percentile_cont",
					[codequery.sqlexpressions.Expr.constFloat(0.5)], ${arg(0)});
			case "mode": macro codequery.sqlexpressions.Expr.withinGroup("mode", [], ${arg(0)});

			case "coalesce": macro codequery.sqlexpressions.Expr.call("COALESCE", ${list(0)});
			case "nullIf": macro codequery.sqlexpressions.Expr.call("NULLIF", ${list(0)});
			case "upper": macro codequery.sqlexpressions.Expr.call("UPPER", ${list(0)});
			case "lower": macro codequery.sqlexpressions.Expr.call("LOWER", ${list(0)});
			case "length": macro codequery.sqlexpressions.Expr.call("LENGTH", ${list(0)});
			case "trim": macro codequery.sqlexpressions.Expr.call("TRIM", ${list(0)});
			case "substring": macro codequery.sqlexpressions.Expr.call("SUBSTRING", ${list(0)});
			case "concat": macro codequery.sqlexpressions.Expr.infix("||", ${list(0)});

			case "utcNow": macro codequery.sqlexpressions.Expr.call(codequery.sqlexpressions.SqlFunctions.UtcNow, []);
			case "today": macro codequery.sqlexpressions.Expr.call(codequery.sqlexpressions.SqlFunctions.Today, []);
			case "isLeapYear": macro codequery.sqlexpressions.Expr.call(codequery.sqlexpressions.SqlFunctions.IsLeapYear, ${list(0)});
			case "daysInMonth": macro codequery.sqlexpressions.Expr.call(codequery.sqlexpressions.SqlFunctions.DaysInMonth, ${list(0)});
			case "dateFromParts": macro codequery.sqlexpressions.Expr.call(codequery.sqlexpressions.SqlFunctions.DateTimeFromParts, ${list(0)});

			// The name is written at the call site, so that what reaches the database is a name.
			case "call":
				final called = switch Unwrap(args[0]).expr {
					case EConst(CString(s, _)): s;
					case _: Context.error("The function's name has to be written at the call site — "
							+ "Sql.call(\"word_similarity\", a, b) — so that what reaches the database is a name and not a value.",
							args[0].pos);
				}
				macro codequery.sqlexpressions.Expr.callNamed($v{called}, ${list(1)});

			case _: Context.error('Sql.$name has no SQL here yet', pos);
		}
	}

	/** The values of a list held in a variable, each as the constant it is when the statement is built. */
	static function ValuesOf(list:Expr):Expr {
		final element = switch Context.typeof(list).follow() {
			case TInst(_.get() => {name: "Array"}, [held]): held;
			case t: Context.error('Sql.isIn takes a list of values, not ${t.toString()}', list.pos);
		}
		final each = ValuedAs(macro item, element);
		return macro [for (item in $list) $each];
	}

	/**
		`x IN (…)` and its negation, over values written at the call site or a collection the query
		holds. A collection is read when the statement is built and sent beside it, one parameter a
		value; values written out are constants in the text.

		NOT IN over a value that may be absent keeps the absent rows: SQL calls the comparison unknown
		and drops the row, where Haxe calls a null value not one of the set. Same disagreement as `!=`,
		same answer — the test is written out beside it.
	**/
	static function Membership(value:Expr, set:Expr, negate:Bool, bound:Map<String, Int>, rows:Array<Type>, pos:Position,
			bindValues:Bool = false):Expr {
		final converted = ToSqlExpression(value, bound, rows);
		final membership = switch Unwrap(set).expr {
			case EArrayDecl(items):
				// A set read off the row is not a set the statement can list.
				for (item in items) {
					if (PathOf(item, bound) != null) {
						return macro(throw "Sql.isIn takes a set the query holds — a collection, values written here, "
							+ "or another query — and this one is read from the row." : codequery.sqlexpressions.ISqlExpression);
					}
				}
				final values = {expr: EArrayDecl([for (item in items) ToSqlExpression(item, bound, rows)]), pos: pos};
				macro codequery.sqlexpressions.Expr.isIn($converted, $values, $v{negate});

			case _:
				// Any collection, not just an array: what matters is that the query holds it. Its
				// element type is what one step of iterating it answers with.
				final element = try {
					Context.typeof(macro $set.iterator().next());
				} catch (_:Dynamic) {
					Context.error('Sql.isIn takes the values as a list written out here or a collection held by the query, not ${Context.typeof(set).toString()}',
						set.pos);
				}
				// Written into the statement as C#'s Contains writes it — IN (1, 2, 3) — unless asked
				// to send the values beside it, as C#'s .In(ids) does.
				final bind = bindValues ? ParameterisedAs(macro v, element) : ValuedAs(macro v, element);
				macro {
					final held = $set;
					if (held == null) {
						throw "The set must be a collection that is there — this one is null.";
					}
					codequery.sqlexpressions.Expr.isIn($converted, [for (v in held) $bind], $v{negate});
				}
		}

		if (negate && IsNullable(value, bound, rows)) {
			return macro codequery.sqlexpressions.Expr.or($membership,
				codequery.sqlexpressions.Expr.equal(${ToSqlExpression(value, bound, rows)}, codequery.sqlexpressions.Expr.constNull()));
		}
		return membership;
	}

	/** Whether a column a lambda reaches is declared as one that may be absent. */
	static function IsNullable(value:Expr, bound:Map<String, Int>, rows:Array<Type>):Bool {
		final reached = PathOf(value, bound);
		if (reached == null) {
			return false;
		}
		return switch MemberTypeOf(reached.path, rows[reached.row], value.pos) {
			case TType(t, _) if (t.get().name == "Null"): true;
			case TAbstract(t, _) if (t.get().name == "Null"): true;
			case _: false;
		}
	}

	/** The `SqlType` a Haxe type casts to. */
	static function SqlTypeOf(type:Type, pos:Position):Expr {
		final name = switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int"}, _): "SqlInt";
			case TAbstract(_.get() => {name: "Float"}, _): "SqlFloat";
			case TAbstract(_.get() => {name: "Bool"}, _): "SqlBool";
			case TInst(_.get() => {name: "String"}, _): "SqlText";
			case TInst(_.get() => {name: "Date"}, _): "SqlTimestamp";
			case t: Context.error('${t.toString()} is not a type SQL can cast to; use Sql.castTo with a SqlType', pos);
		}
		return macro $p{["codequery", "sqlexpressions", "SqlType", name]};
	}

	/**
		`Reduce` — folding a joined query back to one row: `(b, u) -> {b: b, u: u}`. The projection is
		kept in place rather than made into a query of its own, so what follows reads through the
		row it built while the SQL stays the join it was.
	**/
	public static function Reduced(self:Expr, reduce:Expr):Expr {
		final rows = EntitiesOf(self);
		final body = switch reduce.expr {
			case EFunction(_, f): Unwrap(f.expr);
			case _: Context.error("Expected a reduce, e.g. (b, u) -> {b: b, u: u}", reduce.pos);
		}

		// A reduce that builds nothing says so — when the query is built, as the C# does, since a
		// test can catch that and not a compile error.
		if (!body.expr.match(EObjectDecl(_) | ENew(_, _) | ECast({expr: EObjectDecl(_)}, _) | EConst(CIdent(_)))) {
			final message = "A reduce builds a row from the sources it joins — reduce: (b, u) -> {b: b, u: u} — and '"
				+ body.toString() + "' is not a row being built.";
			return macro(throw $v{message} : Dynamic);
		}

		final projected = ConvertProjectionCallback(reduce, rows);
		final selection = projected.selection;
		return Answering(macro(cast $self : codequery.queries.SelectQueryImpl).Reduce($selection), [projected.row]);
	}

	/**
		`Pivot` — one conditional aggregate per pivot value, `SUM(CASE WHEN forColumn = key THEN value END)`,
		beside the group-by columns and grouped by them. Portable: no dialect needs a PIVOT clause.
	**/
	public static function Pivot(self:Expr, result:Expr, forColumn:Expr, value:Expr, aggregate:Expr, pivots:Expr,
			groupBy:Null<Expr>):Expr {
		final rows = EntitiesOf(self);
		final forExpr = ConvertKey(forColumn, rows);
		final valueExpr = ConvertKey(value, rows);

		final columns = switch Unwrap(pivots).expr {
			case EArrayDecl(items):
				[for (item in items) switch Unwrap(item).expr {
					case EObjectDecl(fields):
						var key:Null<Expr> = null;
						var column:Null<Expr> = null;
						for (field in fields) {
							switch field.field {
								case "key": key = Valued(field.expr);
								case "column": column = field.expr;
								case other: Context.error('A pivot names a key and a column, not "$other"', field.expr.pos);
							}
						}
						if (key == null || column == null) {
							Context.error("A pivot is {key: …, column: …}", item.pos);
						}
						macro new codequery.queries.Pivoting.PivotColumn($key, $column);
					case _: Context.error("A pivot is {key: …, column: …}", item.pos);
				}];
			case _: Context.error("The pivots are written out here as a list of {key: …, column: …}", pivots.pos);
		}
		final list = {expr: EArrayDecl(columns), pos: pivots.pos};

		final grouped = Omitted(groupBy) ? macro null : ConvertProjection(groupBy, rows).selection;
		final resultType = Context.getType(switch result.expr {
			case EConst(CIdent(name)): name;
			case EField(_, _, _): new Printer().printExpr(result);
			case _: Context.error("Name the row type the pivot answers with, e.g. .Pivot(RegionPivot, …)", result.pos);
		});
		final shape = ShapeOf(resultType);
		final pivoted = macro codequery.queries.Pivoting.Apply((cast $self : codequery.queries.SelectQueryImpl),
			$forExpr, $valueExpr, $aggregate, $list, $grouped, $shape);
		return Answering(pivoted, [resultType]);
	}

	/** The statement behind a query handed to `Sql`. */
	/** The statement behind a query handed to `Sql`, as it stands inside another. */
	static function Statement(query:Expr):Expr {
		return macro codequery.queries.Subquery.Of((cast $query : codequery.queries.SelectQueryImpl));
	}

	/** `INTERVAL 'n unit'`, which is a literal of its own rather than a function of two values. */
	static function Interval(count:Expr, unit:Expr):Expr {
		return macro codequery.sqlexpressions.Expr.raw("INTERVAL \'" + $count + " " + $unit + "\'");
	}

	/** The same value as `Valued`, but sent beside the statement rather than written into it. */
	static function Parameterised(value:Expr):Expr {
		return ParameterisedAs(value, Context.typeof(value));
	}

	/** The same, where the type is known and the expression cannot be typed on its own. */
	public static function ParameterisedAs(value:Expr, type:Type):Expr {
		final factory = Factory(switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int"}, _): "paramInt";
			case TAbstract(_.get() => {name: "Float"}, _): "paramFloat";
			case TAbstract(_.get() => {name: "Bool"}, _): "paramBool";
			case TInst(_.get() => {name: "String"}, _): "paramString";
			case TInst(_.get() => {name: "Date"}, _): "paramDate";
			case t: Context.error('${t.toString()} is not something a parameter can hold', value.pos);
		});
		return macro $factory($value);
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
		How a column of `row` is reached, by the path of members named to get to it.

		In a callback the parameter *is* the row's columns, so the path is read off it: `b.price.zar`
		stays `b.price.zar`, now reaching a `ColumnSqlExpression`. Inline, the column is built where
		it is used, on the position of the parameter it was reached through.
	**/
	static function ColumnFor(row:Type, index:Int, path:Array<String>, pos:Position):Expr {
		MemberOf(path, row, pos);
		final parameter = CallbackName(index);
		if (parameter == null) {
			return InlineColumn(row, index, path, pos);
		}
		var reached = macro $i{parameter};
		for (step in path) {
			reached = {expr: EField(reached, step), pos: pos};
		}
		return reached;
	}

	/** The column at `path`, built on the parameter's position, named as its columns are named. */
	static function InlineColumn(row:Type, index:Int, path:Array<String>, pos:Position):Expr {
		final column = ColumnPathOf(row, path, pos);
		final name = column.name;
		final type = column.type;
		return macro new codequery.sqlexpressions.ColumnSqlExpression(
			codequery.sqlexpressions.ParameterSqlSource.At($v{index}), $v{name}, $type);
	}

	/**
		The name of the column at `path` and what it holds. An entity's field contributes its
		`@columnName`; a structure's, the field's own name — the same rule the columns handed to a
		callback follow, so the two shapes agree on every name.
	**/
	static function ColumnPathOf(row:Type, path:Array<String>, pos:Position):{name:String, type:Expr} {
		var held = row;
		final segments:Array<String> = [];
		var type:Expr = macro codequery.sqlexpressions.SqlType.SqlUnknown;
		for (step in path) {
			final field = FieldNamed(held, step);
			if (field == null) {
				Context.error('${held.toString()} has no field "$step"', pos);
			}
			segments.push(IsStructure(held) ? field.name : ColumnsBuilder.ColumnNameOf(field));
			type = ColumnsBuilder.SqlTypeOfField(field);
			held = field.type;
		}
		return {name: segments.join(ColumnsBuilder.Separator), type: type};
	}

	/** Whether a row is an anonymous structure — what a projection answers with. */
	static function IsStructure(row:Type):Bool {
		return row.follow().match(TAnonymous(_));
	}

	/** The fields a row has, whether it is a class or a structure. */
	static function FieldsOf(row:Type):Null<Array<ClassField>> {
		return switch row.follow() {
			case TInst(t, _): t.get().fields.get();
			case TAnonymous(a): a.get().fields;
			case _: null;
		}
	}

	/**
		Checks that the row really has this path, so that a typo is a compile error here rather than
		a confusing one further on. Answers with the name the column is known by, which for a nested
		member is the path to it.
	**/
	static function MemberOf(path:Array<String>, entity:Type, pos:Position):String {
		var row = entity;
		for (step in 0...path.length) {
			final found = FieldNamed(row, path[step]);
			if (found == null) {
				final reached = step == 0
					? row.toString()
					: '${row.toString()} (reached by ${path.slice(0, step).join(".")})';
				Context.error('$reached has no field "${path[step]}"', pos);
			}
			if (step == path.length - 1) {
				break;
			}
			row = found.type;
		}

		return path.join(ColumnsBuilder.Separator);
	}

	/** What the member at the end of a path holds. */
	static function MemberTypeOf(path:Array<String>, entity:Type, pos:Position):Type {
		var row = entity;
		var held:Null<Type> = null;
		for (step in 0...path.length) {
			final found = FieldNamed(row, path[step]);
			if (found == null) {
				Context.error('${row.toString()} has no field "${path[step]}"', pos);
			}
			held = found.type;
			row = found.type;
		}
		return held;
	}

	static function FieldNamed(row:Type, name:String):Null<ClassField> {
		final fields = FieldsOf(row);
		if (fields == null) {
			return null;
		}
		for (field in fields) {
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
	public static function ConvertProjection(projection:Expr, rows:Array<Type>, ?query:Expr, asCallback:Bool = false):{selection:Expr, row:Type} {
		final projection = ResolveLambda(projection);
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

		// A subquery the projection writes has the outer row's columns put in before it is typed.
		final body = LambdaCalls.PrepareSubqueries(Unwrap(fn.expr), bound, rows);

		// Typed first, and deliberately: the walk below only reads syntax, so if it ran first an
		// editor would get nothing back from inside the projection. Typing is what answers that.
		final row = ProjectedRow({args: fn.args, ret: fn.ret, expr: {expr: EReturn(body), pos: body.pos}}, rows,
			projection.pos);

		// An aggregate over a window the query named reaches the window through the query.
		final enclosing = WindowConverter.CurrentQuery;
		WindowConverter.CurrentQuery = query;
		final names = [for (arg in fn.args) arg.name];
		final selection = try Converting(asCallback ? names : null, () -> ToProjection(body, bound, rows)) catch (failed:Dynamic) {
			WindowConverter.CurrentQuery = enclosing;
			throw failed;
		}
		WindowConverter.CurrentQuery = enclosing;
		return {selection: asCallback ? Callback(names, rows, selection, projection.pos) : selection, row: row};
	}

	/** The projection as a callback over the rows' columns, which is what `select` is handed. */
	public static function ConvertProjectionCallback(projection:Expr, rows:Array<Type>):{selection:Expr, row:Type} {
		return ConvertProjection(projection, rows, null, true);
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
			// A value whose type nothing settles — `Sql.castTo`'s `TTo` — is a row of no particular type.
			case TFun(_, ret): ret.toComplexType() == null ? TDynamic(null) : ret;
			case t: Context.error('A projection must answer with something; this one is ${t.toString()}', pos);
		}
	}

	static function ToProjection(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		// Flattened by the builder: a whole row or an object built here is its columns, named along
		// the path that reaches each, and a lone expression is itself.
		return ProjectionBuilder.Build(e, bound, rows);
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
		// per window the query has picked up — the windows come after the rows they are over.
		final entities = EntityRows(rows);
		final windows = rows.length - entities.length;
		if (fn.args.length != 1 + windows) {
			Context.error('Expected an aggregate projection taking ${1 + windows} parameter${windows == 0 ? "" : "s"}',
				projection.pos);
		}

		TypeAggregation(fn, rows, projection.pos);

		final bound = new Map<String, Int>();
		bound.set(fn.args[0].name, 0);
		final named = [for (index in 0...windows) fn.args[index + 1].name => entities.length + index];

		// One aggregate on its own names nothing, as one expression in a projection does not.
		final members = switch Unwrap(fn.expr).expr {
			case EObjectDecl(fields): fields;
			case _: [{field: "", expr: Unwrap(fn.expr)}];
		}

		final built = Converting(null, () -> {
			expr: EArrayDecl([
				for (field in members) {
					final value = ToAggregate(field.expr, fn.args[0].name, named, entities, query);
					macro new codequery.sqlexpressions.ProjectionMember($v{field.field}, $value);
				}
			]),
			pos: projection.pos
		});

		return {
			selection: macro new codequery.sqlexpressions.ProjectionSqlExpression($built),
			row: AggregatedValue(ProjectedRow(fn, AggregationRows(rows), projection.pos))
		};
	}

	/**
		The parameter types an aggregate projection is typed against: the set of aggregates over
		the query's rows — `IAggregateSet` for one row, `IAggregateSet2` for two, and so on, as
		the C# has one per width — then a window for each the query defined.
	/**
		The parameter types an aggregate projection is typed against: the set over however many
		rows the query has — `IAggregateSet` for one, `IAggregateSet2` for two, and so on — then
		a window for each the query has defined.
	**/
	/** The value an aggregate stands for: `Aggregate<Row, Float>` is a Float where it is read. */
	static function AggregatedValue(type:Type):Type {
		return switch type.follow() {
			case TAbstract(_.get() => {name: "Aggregate"}, [_, value]): value;
			case _: type;
		}
	}

	/** The parameter types an aggregate projection is typed against. */
	static function AggregationRows(rows:Array<Type>):Array<Type> {
		final entities = EntityRows(rows);
		final set = Context.getType("codequery.IAggregateSet" + (entities.length == 1 ? "" : Std.string(entities.length)));
		final window = Context.getType("codequery.INamedWindow");
		final typed = [switch set {
			case TInst(t, _): TInst(t, entities);
			case t: t;
		}];
		for (_ in entities.length...rows.length) {
			typed.push(window);
		}
		return typed;
	}

	static function TypeAggregation(fn:Function, rows:Array<Type>, pos:Position):Void {
		final signature = ComplexType.TFunction([for (row in AggregationRows(rows)) row.toComplexType()], macro :Dynamic);
		final lambda = {expr: EFunction(FAnonymous, fn), pos: pos};
		Context.typeExpr(macro @:pos(pos) ($lambda : $signature));
	}

	/**
		One member of an aggregate projection: a call on the aggregate set, perhaps over a window.
		`entities` are the rows the query is over, which is what a selector inside is written over.
	**/
	static function ToAggregate(e:Expr, set:String, windows:Map<String, Int>, entities:Array<Type>, query:Expr):Expr {
		final e = Unwrap(e);
		return switch e.expr {
			// `<aggregate>.over(w)`
			case ECall({expr: EField({expr: inner}, "over", _)}, [window]):
				final named = switch Unwrap(window).expr {
					case EConst(CIdent(name)) if (windows.exists(name)): windows[name];
					case _: Context.error("over() takes a window this query has defined", window.pos);
				}
				final aggregate = ToAggregate({expr: inner, pos: e.pos}, set, windows, entities, query);
				macro $aggregate.OverWindow(${WindowAt(query, named)});

			// `<aggregate>.overRows(w -> …)` — a window written out rather than named.
			case ECall({expr: EField({expr: inner}, "overRows", _)}, [spec]):
				final window = ConvertWindow(spec, entities);
				final partitionBy = window.partitionBy;
				final orderBy = window.orderBy;
				final frame = window.frame;
				final aggregate = ToAggregate({expr: inner, pos: e.pos}, set, windows, entities, query);
				macro $aggregate.OverDefinition(
					new codequery.sqlexpressions.WindowDefinition($partitionBy, $orderBy, $frame));

			// `<aggregate>.filter(r -> …)`
			case ECall({expr: EField({expr: inner}, "filter", _)}, [predicate]):
				final condition = Convert(predicate, entities);
				final aggregate = ToAggregate({expr: inner, pos: e.pos}, set, windows, entities, query);
				macro $aggregate.Filtered($condition);

			// `<aggregate>.distinct()`
			case ECall({expr: EField({expr: inner}, "distinct", _)}, []):
				final aggregate = ToAggregate({expr: inner, pos: e.pos}, set, windows, entities, query);
				macro $aggregate.Distinctly();

			// `<set>.key(r -> r.unitId)` — the grouping key, or one member of it, which is a column
			// of the entities rather than an aggregate over them.
			case ECall({expr: EField({expr: EConst(CIdent(name))}, "key", _)}, [selector]) if (name == set):
				ConvertKey(selector, entities);

			case ECall({expr: EField({expr: EConst(CIdent(name))}, fn, _)}, args) if (name == set):
				Aggregate(fn, args, entities, e.pos);

			case _:
				Context.error('An aggregate projection selects aggregates, not ${e.toString()}', e.pos);
		}
	}

	static function Aggregate(fn:String, args:Array<Expr>, rows:Array<Type>, pos:Position):Expr {
		final row = rows;

		// The group's key is not an aggregate: it is the column itself, read beside them.
		if (fn == "key") {
			return ConvertKey(args[0], row);
		}

		// The window functions are not aggregates and have a node of their own.
		final windowed = WindowFunctionNamed(fn);
		if (windowed != null) {
			final arguments = {
				expr: EArrayDecl(args.length == 0 ? [] : [ConvertKey(args[0], rows)].concat(
					args.length > 1 ? [ToSqlExpression(args[1], new Map(), rows)] : [])),
				pos: pos
			};
			return macro new codequery.sqlexpressions.WindowFunctionExpression(
				$p{["codequery", "sqlexpressions", "WindowFunction", windowed]}, $arguments);
		}

		final kind = macro $p{["codequery", "sqlexpressions", "AggregateType", AggregateNamed(fn, pos)]};
		if (fn == "count") {
			return macro new codequery.sqlexpressions.AggregateSqlExpression($kind);
		}
		final argument = ConvertKey(args[0], row);
		final distinct = fn == "countDistinct" || fn == "sumDistinct";
		return macro new codequery.sqlexpressions.AggregateSqlExpression($kind, $argument, $v{distinct});
	}

	static function WindowFunctionNamed(fn:String):Null<String> {
		return switch fn {
			case "rowNumber": "RowNumber";
			case "rank": "Rank";
			case "denseRank": "DenseRank";
			case "lead": "Lead";
			case "lag": "Lag";
			case "firstValue": "FirstValue";
			case "lastValue": "LastValue";
			case _: null;
		}
	}

	static function AggregateNamed(fn:String, pos:Position):String {
		return switch fn {
			case "count" | "countDistinct" | "countValues": "Count";
			case "sum" | "sumDistinct": "Sum";
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
	public static function ConvertWindow(spec:Expr, rows:Array<Type>):{partitionBy:Expr, orderBy:Expr, frame:Expr} {
		final fn = switch spec.expr {
			case EFunction(_, f) if (f.args.length == 1): f;
			case _: Context.error("Expected a window spec, e.g. w -> w.PartitionBy(a -> a.id)", spec.pos);
		}

		final partitionBy:Array<Expr> = [];
		final orderBy:Array<Expr> = [];
		final frame:Array<Expr> = [];
		WalkWindow(Unwrap(fn.expr), fn.args[0].name, rows, partitionBy, orderBy, frame);

		return {
			partitionBy: {expr: EArrayDecl(partitionBy), pos: spec.pos},
			orderBy: {expr: EArrayDecl(orderBy), pos: spec.pos},
			frame: frame.length == 0 ? macro null : frame[0]
		};
	}

	/** The chain is read from the outside in, so the terms are collected in the order written. */
	static function WalkWindow(e:Expr, spec:String, rows:Array<Type>, partitionBy:Array<Expr>, orderBy:Array<Expr>,
			frame:Array<Expr>):Void {
		switch Unwrap(e).expr {
			case EConst(CIdent(name)) if (name == spec):
				return;

			case ECall({expr: EField(owner, call, _)}, args):
				WalkWindow(owner, spec, rows, partitionBy, orderBy, frame);
				if (call == "Rows" || call == "Range" || call == "RowsBetween" || call == "RangeBetween") {
					final kind = macro $p{["codequery", "sqlexpressions", "FrameKind", call == "RowsBetween" ? "Rows" : (call == "RangeBetween" ? "Range" : call)]};
					frame.push(macro new codequery.sqlexpressions.WindowFrame($kind, ${args[0]}, ${args[1]}));
					return;
				}
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
						Context.error('A window is partitioned, ordered and framed; $call is none of them', e.pos);
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

	/** The same, as a callback over the row's columns answering with the column. */
	public static function ConvertColumnCallback(selector:Expr, rows:Array<Type>):Expr {
		return ConvertLambda(selector, rows, macro :Dynamic, "a column selector, e.g. g -> g.email", true);
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

	/** The same, a lambda becoming a callback over the rows' columns and a value the constant it is. */
	public static function ConvertValueCallback(value:Expr, rows:Array<Type>):Expr {
		return switch value.expr {
			case EFunction(_, _): ConvertKeyCallback(value, rows);
			case _: Valued(value);
		}
	}

	/** A runtime value, as the constant it will be by the time the statement runs. */
	public static function Valued(value:Expr):Expr {
		return ValuedAs(value, Context.typeof(value));
	}

	/** The same, where the type is already known and the expression cannot be typed on its own. */
	public static function ValuedAs(value:Expr, type:Type):Expr {
		// Unwrapped first: an enum abstract is its underlying number by the time SQL sees it, and
		// SqlDate is a date.
		final factory = Factory(switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int"}, _): "constInt";
			case TAbstract(_.get() => {name: "Float"}, _): "constFloat";
			case TAbstract(_.get() => {name: "Bool"}, _): "constBool";
			case TInst(_.get() => {name: "String"}, _): "constString";
			case TInst(_.get() => {name: "Date"}, _): "constDate";
			case t: Context.error('${t.toString()} is not something a column can hold', value.pos);
		});
		return macro $factory($value);
	}

	/** The column names a conflict is judged on — one lambda, or a structure naming several. */
	public static function ConvertColumnNames(columns:Expr, rows:Array<Type>):Expr {
		final keys = ConvertKeySet(columns, rows);
		return macro codequery.sqlexpressions.ProjectionKeys.NamesOf($keys);
	}

	/** An insert answers with an insert, over the same row. */
	public static function AnsweringInsert(statement:Expr, self:Expr):Expr {
		final rows = EntitiesOf(self);
		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: "IInsertQuery",
			params: [TPType(rows[0].toComplexType())]
		});
		return macro(cast $statement : $queryType);
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

	/** `UPDATE … FROM` and `DELETE … USING`, which reach a second row. */
	public static function MutationFrom(table:Expr, source:Expr, begins:String, answers:String):Expr {
		final rows = [EntityOf(table), EntityOf(source)];
		final statement = macro(cast $source : codequery.queries.SelectQueryImpl);
		final begun = macro $p{["codequery", "queries", "MutationQueryImpl", begins]}($table.Table, $statement, $table.Shape);

		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: answers,
			params: [for (row in rows) TPType(row.toComplexType())]
		});
		return macro(cast $begun : $queryType);
	}

	/** Several entities in one statement — the same columns, a row of values each. */
	public static function ConvertInsertMany(table:Expr, entries:Expr, entity:Type):Expr {
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', entries.pos);
		}

		// The columns are the same for every row, so they are read once, off a name standing for
		// whichever entity is being written.
		final columns:Array<Expr> = [];
		final values:Array<Expr> = [];
		InsertMembers(row, macro entry, [], [], columns, values);

		final columnList = {expr: EArrayDecl(columns), pos: entries.pos};
		final valueList = {expr: EArrayDecl(values), pos: entries.pos};
		return macro codequery.queries.InsertStatement.Many($table, $columnList,
			[for (entry in $entries) $valueList]);
	}

	/** `INSERT … SELECT`, where the rows come from a query. */
	public static function ConvertInsertFrom(table:Expr, source:Expr, entity:Type):Expr {
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', source.pos);
		}

		final columns:Array<Expr> = [];
		final values:Array<Expr> = [];
		InsertMembers(row, macro entry, [], [], columns, values);

		final columnList = {expr: EArrayDecl(columns), pos: source.pos};
		final statement = macro(cast $source : codequery.queries.SelectQueryImpl).ToExpression();
		return macro codequery.queries.InsertStatement.FromQuery($table, $columnList, $statement);
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
				// Sent beside the statement rather than written into it, which is the
				// strategy's default and the safer one.
				values.push(ParameterisedAs(read, field.type));
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
	public static function Join(self:Expr, source:Expr, on:Null<Expr>, joinType:String, ?reduce:Expr):Expr {
		if (Omitted(on) && IsRelation(source)) {
			return RelationJoin(self, source, joinType);
		}

		final rows = EntitiesOf(self).concat([EntityOf(source)]);
		if (rows.length > MaxRows) {
			Context.error('A query can join up to $MaxRows rows, as in C#; this one would have ${rows.length}',
				source.pos);
		}

		final kind = macro $p{["codequery", "sqlexpressions", "JoinType", joinType]};
		final query = macro(cast $self : codequery.queries.SelectQueryImpl);
		final inner = macro(cast $source : codequery.queries.SelectQueryImpl);

		// A cross join has no condition, so it is left off rather than passed as null.
		final joined = if (Omitted(on)) {
			IsTable(source) ? macro $query.JoinTable($kind, $source) : macro $query.JoinQuery($kind, $inner);
		} else {
			final condition = ConvertCallback(on, rows);
			IsTable(source)
				? macro $query.JoinTable($kind, $source, $condition)
				: macro $query.JoinQuery($kind, $inner, $condition);
		}

		// A join may fold the rows it now has back into one, as C#'s `reduce:` argument does.
		final answered = Answering(joined, rows);
		return Omitted(reduce) ? answered : Reduced(answered, reduce);
	}

	/** The row a window arrives as. */
	public static function WindowRow():Type {
		return Context.getType("codequery.INamedWindow");
	}

	/**
		A relationship rather than a source: a function answering with the join's condition, as
		C#'s `Booking.WithUnit` does — `public static function WithUnit() return (b:Booking, u:Unit)
		-> u.id == b.unitId`. The table joined to is the last parameter's, so the join says only
		what relates the two.
	**/
	static function IsRelation(source:Expr):Bool {
		return RelationType(source) != null;
	}

	/** The condition's type behind a relationship: the function's, or what it answers with. */
	static function RelationType(source:Expr):Null<Type> {
		final type = try Context.typeof(source) catch (_:Dynamic) return null;
		return switch type.follow() {
			case TFun([], returned):
				switch returned.follow() {
					case TFun(_, _): returned;
					case _: null;
				}
			case TFun(_, _): type;
			case _: null;
		}
	}

	/**
		A join by relationship: the table is the one the relationship names, and its condition is
		the relationship's, read over the rows of this query it asks for — by their types, so a
		relationship on the row the query started from reads however many joins have happened
		since — and the table joined last.
	**/
	static function RelationJoin(self:Expr, relation:Expr, joinType:String):Expr {
		final parameters = switch RelationType(relation).follow() {
			case TFun(args, _): args.map(arg -> arg.t);
			case t: Context.error('A relationship is a function of the rows it joins, not ${t.toString()}', relation.pos);
		}
		if (parameters.length < 2) {
			Context.error("A relationship names the row it hangs off and the row it joins to", relation.pos);
		}

		final target = parameters[parameters.length - 1];
		final rows = EntitiesOf(self).concat([target]);
		if (rows.length > MaxRows) {
			Context.error('A query can join up to $MaxRows rows, as in C#; this one would have ${rows.length}',
				relation.pos);
		}

		final lambda = ResolveLambda(relation);
		final fn = switch lambda.expr {
			case EFunction(_, f) if (f.args.length == parameters.length): f;
			case _: Context.error("A relationship answers with a lambda over the rows it joins, e.g. (b, u) -> u.id == b.unitId",
					relation.pos);
		}
		TypeLambda(lambda, parameters, macro :Bool);

		// Each parameter but the last names the row of its type; the last is the table joined.
		final bound = new Map<String, Int>();
		for (index => arg in fn.args) {
			bound.set(arg.name, index == fn.args.length - 1 ? rows.length - 1 : RowOfType(rows, parameters[index], relation.pos));
		}
		// The callback takes every row the query has, under the relationship's names where it
		// names them and unused names where it does not.
		final names = [for (index in 0...rows.length) '_row$index'];
		for (name => index in bound) {
			names[index] = name;
		}
		final condition = Callback(names, rows, Converting(names, () -> ToSqlExpression(fn.expr, bound, rows)), relation.pos);

		final tableType = target.toComplexType();
		final tableName = ColumnsBuilder.TableNameOfType(target);
		final shape = ShapeOf(target);
		final table = macro new codequery.DbTable<$tableType>(new codequery.QualifiedTableName($v{tableName}), null, null, null, $shape);
		final kind = macro $p{["codequery", "sqlexpressions", "JoinType", joinType]};
		final query = macro(cast $self : codequery.queries.SelectQueryImpl);
		return Answering(macro $query.JoinTable($kind, $table, $condition), rows);
	}

	/** The first of the query's rows that is of `type` — the one a relationship's parameter reads. */
	static function RowOfType(rows:Array<Type>, type:Type, pos:Position):Int {
		for (index in 0...rows.length - 1) {
			if (Context.unify(rows[index], type) && Context.unify(type, rows[index])) {
				return index;
			}
		}
		return Context.error('This query has no row of ${type.toString()} for the relationship to read', pos);
	}

	/**
		The recursive member of a `Recursive` CTE, built against the CTE itself: the lambda is
		called with a query over a table of the CTE's name, typed as the rows this query is over.
	**/
	public static function RecursiveMember(member:Expr, name:Expr, rows:Array<Type>):Expr {
		final fn = switch member.expr {
			case EFunction(_, f) if (f.args.length == 1): f;
			case _: Context.error("Expected a lambda over the CTE, e.g. org -> Query.select(Employee).InnerJoin(org, …)", member.pos);
		}
		final queryType = QueryTypeOf(rows);
		final typed = {
			expr: EFunction(FAnonymous, {args: [{name: fn.args[0].name, type: queryType}], ret: null, expr: fn.expr}),
			pos: member.pos
		};
		final shape = ShapeOf(rows[0]);
		final selfReference = macro(cast codequery.queries.SelectQueryImpl.OverTable(new codequery.QualifiedTableName($name), null, $shape) : $queryType);
		return macro(cast ($typed)($selfReference) : codequery.queries.SelectQueryImpl);
	}

	/**
		One grouping set — a lambda naming one key, or a structure naming several:
		`r -> r.unitId`, or `r -> {a: r.unitId, b: r.guestId}`.
	**/
	public static function ConvertKeySet(set:Expr, rows:Array<Type>):Expr {
		final body = switch set.expr {
			case EFunction(_, f): Unwrap(f.expr);
			case _: Context.error("Expected a grouping set, e.g. r -> r.unitId", set.pos);
		}
		// `r -> {}` is the empty set — the grand total — which Haxe reads as an empty block.
		if (body.expr.match(EBlock([]))) {
			return macro [];
		}
		// One key is not a structure, so it is not a projection either.
		if (!body.expr.match(EObjectDecl(_))) {
			final key = ConvertKey(set, rows);
			return macro [$key];
		}
		final selection = ConvertProjection(set, rows).selection;
		return macro codequery.sqlexpressions.ProjectionKeys.Of($selection);
	}

	/**
		The same grouping set as a callback over the rows' columns, answering with one key, a
		structure of several, or nothing at all for the grand total.
	**/
	public static function ConvertKeySetCallback(set:Expr, rows:Array<Type>):Expr {
		final fn = switch set.expr {
			case EFunction(_, f): f;
			case _: Context.error("Expected a grouping set, e.g. r -> r.unitId", set.pos);
		}
		final body = Unwrap(fn.expr);
		if (body.expr.match(EBlock([]))) {
			return Callback([for (arg in fn.args) arg.name], rows, macro [], set.pos);
		}
		if (!body.expr.match(EObjectDecl(_))) {
			return ConvertKeyCallback(set, rows);
		}
		return ConvertProjectionCallback(set, rows).selection;
	}

	/** `UNION`, `INTERSECT` and `EXCEPT`, which put two statements' rows together. */
	public static function SetOperation(self:Expr, other:Expr, type:String):Expr {
		final rows = EntitiesOf(self);
		final kind = macro $p{["codequery", "sqlexpressions", "SetOperationType", type]};
		final right = macro(cast $other : codequery.queries.SelectQueryImpl);
		return Answering(macro(cast $self : codequery.queries.SelectQueryImpl).UnionWith($kind, $right), rows);
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
		final queryType = QueryTypeOf(rows);
		return macro(cast $query : $queryType);
	}

	/** The `ISelectQueryN` type for however many rows. */
	public static function QueryTypeOf(rows:Array<Type>):ComplexType {
		final name = "ISelectQuery" + (rows.length == 1 ? "" : Std.string(rows.length));
		return TPath({
			pack: ["codequery", "queries"],
			name: name,
			params: [for (row in rows) TPType(row.toComplexType())]
		});
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

	// ---- owned objects named whole ----------------------------------------------------------------
	//
	// An object spread over columns — `[ColumnObject(Flatten)]` in C#, any object-typed member here —
	// has no column of its own. Naming a field of it names a column, and that is handled above.
	// Naming the object itself is what these handle: in a projection it is every column it is spread
	// over, under the member's name (`cost_amount`, or `amount` where it stands alone); assigned
	// whole, it is every one of those columns assigned.

	/**
		The members one field of a projection selects — usually one, several for an owned object,
		and several again for an object the projection builds (`cost: {amount: r.price, …}`), whose
		members are named for it as a flattened object's columns are.
	**/
	static function ProjectionMembersOf(name:String, value:Expr, bound:Map<String, Int>, rows:Array<Type>):Array<Expr> {
		final value = Unwrap(value);
		final prefix = name == "" ? "" : name + ColumnsBuilder.Separator;

		switch value.expr {
			case EObjectDecl(fields):
				final members:Array<Expr> = [];
				for (field in fields) {
					for (member in ProjectionMembersOf(prefix + field.field, field.expr, bound, rows)) {
						members.push(member);
					}
				}
				return members;
			case _:
		}

		final leaves = ObjectLeaves(value, bound, rows);
		if (leaves == null) {
			final converted = ToSqlExpression(value, bound, rows);
			return [macro new codequery.sqlexpressions.ProjectionMember($v{name}, $converted)];
		}

		final reached = PathOf(value, bound);
		return [
			for (leaf in leaves) {
				final column = ColumnFor(rows[reached.row], reached.row, reached.path.concat(leaf), value.pos);
				final member = prefix + leaf.join(ColumnsBuilder.Separator);
				macro new codequery.sqlexpressions.ProjectionMember($v{member}, $column);
			}
		];
	}

	/**
		The paths to every column an expression naming an owned object is spread over, or null
		where the expression is not one — a value, a column, or nothing of the row's.
	**/
	static function ObjectLeaves(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Null<Array<Array<String>>> {
		final reached = PathOf(Unwrap(e), bound);
		if (reached == null || reached.path.length == 0) {
			return null;
		}
		final row = rows[reached.row];
		if (FieldNamed(row, reached.path[0]) == null) {
			return null;
		}
		return LeavesOf(MemberTypeOf(reached.path, row, e.pos), []);
	}

	/** The columns a type is spread over, as paths of field names — or null where it is a value. */
	static function LeavesOf(type:Type, visited:Array<String>):Null<Array<Array<String>>> {
		final held = switch type.follow() {
			case TInst(t, _):
				final cls = t.get();
				final path = cls.pack.concat([cls.name]).join(".");
				(path == "String" || path == "Date" || visited.indexOf(path) >= 0) ? null : cls;
			case _: null;
		}
		if (held == null) {
			return null;
		}

		final leaves:Array<Array<String>> = [];
		final name = held.pack.concat([held.name]).join(".");
		for (field in held.fields.get()) {
			if (!field.isPublic || !field.kind.match(FVar(AccNormal | AccNo, _))) {
				continue;
			}
			final nested = LeavesOf(field.type, visited.concat([name]));
			if (nested == null) {
				leaves.push([field.name]);
			} else {
				for (leaf in nested) {
					leaves.push([field.name].concat(leaf));
				}
			}
		}
		return leaves;
	}

	/**
		A `Set` whose column is an owned object, as one assignment per column it is spread over —
		or null where the column is a plain one and `Set` carries on as it does.

		The value is an object written out, `g -> {forex: g.price.forex, …}`, and every field has a
		column: one left unsaid would keep what it held, which is not what assigning a whole object
		means, so it is refused by name.
	**/
	public static function ConvertObjectAssignment(column:Expr, value:Expr, rows:Array<Type>):Null<Array<{column:Expr, value:Expr}>> {
		final selector = ResolveLambda(column);
		final fn = switch selector.expr {
			case EFunction(_, f): f;
			case _: return null;
		}
		final bound = new Map<String, Int>();
		for (index => arg in fn.args) {
			bound.set(arg.name, index);
		}
		final target = Unwrap(fn.expr);
		final leaves = ObjectLeaves(target, bound, [rows[0]]);
		if (leaves == null) {
			return null;
		}

		final assigned = switch ResolveLambda(value).expr {
			case EFunction(_, f) if (f.args.length == rows.length): f;
			case _: Context.error("Assigning a whole object takes a lambda answering with it written out, e.g. g -> {zar: g.price.zar * 1.15, …}",
					value.pos);
		}
		final assignedBound = new Map<String, Int>();
		for (index => arg in assigned.args) {
			assignedBound.set(arg.name, index);
		}
		final reached = PathOf(target, bound);
		final object = reached.path.join(".");
		final columnNames = [fn.args[0].name];
		final valueNames = [for (arg in assigned.args) arg.name];

		return [
			for (leaf in leaves) {
				final given = FieldOfDecl(Unwrap(assigned.expr), leaf);
				if (given == null) {
					Context.error('Assigning $object whole leaves ${object}.${leaf.join(".")} unsaid; every field of it has a column, so every field is given',
						value.pos);
				}
				{
					column: Callback(columnNames, [rows[0]],
						Converting(columnNames, () -> ColumnFor(rows[reached.row], reached.row, reached.path.concat(leaf), target.pos)), target.pos),
					value: Callback(valueNames, rows,
						Converting(valueNames, () -> ToSqlExpression(given, assignedBound, rows)), value.pos)
				}
			}
		];
	}

	/** The expression an object written out gives a field at `path`, or null where it is left out. */
	static function FieldOfDecl(decl:Expr, path:Array<String>):Null<Expr> {
		var current = Unwrap(decl);
		for (step in path) {
			final fields = switch current.expr {
				case EObjectDecl(fields): fields;
				case _: return null;
			}
			var found:Null<Expr> = null;
			for (field in fields) {
				if (field.field == step) {
					found = field.expr;
				}
			}
			if (found == null) {
				return null;
			}
			current = Unwrap(found);
		}
		return current;
	}
	#end
}
