package codequery.sqlexpressions;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
#end

/**
	What a lambda can say beyond its operators and `Sql`'s calls.

	A query asked a question — `q.Any()`, `q.Sum(o -> o.total)`, `q.Contains(c.id)` — a value the
	lambda closed over, a string searched, a list tested for membership, a CASE written out with
	`DbCase`, a guard on a captured list. Each is one conversion; they are here rather than in
	`ExpressionConverter` so that file keeps to the shape of a lambda and this one to what a lambda
	can call.
**/
@:access(codequery.sqlexpressions.ExpressionConverter)
class LambdaCalls {
	#if macro
	/** The questions a query is asked inside a lambda, named as C#'s LINQ-shaped methods are. */
	static final SubqueryMethods = [
		"Any", "All", "Contains", "Sum", "Max", "Min", "Avg", "Count", "FirstOrDefault", "FetchFirst",
		"FetchFirstOrDefault", "ToList"
	];

	/** Which argument of a `Sql` call is the query, or -1 where none is. */
	static function SubqueryArgument(name:String):Int {
		return switch name {
			case "scalar" | "correlated" | "exists" | "notExists" | "any" | "all" | "some": 0;
			case "inQuery" | "notInQuery": 1;
			case _: -1;
		}
	}

	/** The name of a `Sql.<name>` call, or null for anything else. */
	static function SqlCallName(callee:Expr):Null<String> {
		return switch callee.expr {
			case EField({expr: EConst(CIdent("Sql"))}, name, _): name;
			case EField({expr: EField({expr: EConst(CIdent("codequery"))}, "Sql", _)}, name, _): name;
			case _: null;
		}
	}

	// ---- subqueries inside a lambda -----------------------------------------------------------------

	/**
		Put the outer row's columns into every subquery the body writes, before the body is typed.

		A subquery is built by its own macro calls, which bind their parameters from zero in their own
		statement and know nothing of the row outside — so the outer row's columns are substituted in
		first, each marked as a statement further out, exactly as a lateral's body is treated. It has
		to happen before typing: typing the body expands the subquery's macros, and they must see the
		columns already put in.
	**/
	public static function PrepareSubqueries(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		return switch e.expr {
			case ECall(callee, args) if (SqlCallName(callee) != null && SubqueryArgument(SqlCallName(callee)) >= 0):
				final at = SubqueryArgument(SqlCallName(callee));
				final prepared = [
					for (index => arg in args)
						index == at ? ExpressionConverter.SubstituteOuter(arg, bound, rows) : PrepareSubqueries(arg, bound, rows)
				];
				{expr: ECall(callee, prepared), pos: e.pos};

			case ECall(callee = {expr: EField(owner, method, _)}, args)
				if (SubqueryMethods.indexOf(method) >= 0 && ExpressionConverter.PathOf(owner, bound) == null):
				final query = ExpressionConverter.SubstituteOuter(owner, bound, rows);
				// A predicate or selector is written inside the subquery; a value handed to Contains
				// is not, it belongs to the statement the lambda is written over.
				final prepared = method == "Contains"
					? [for (arg in args) PrepareSubqueries(arg, bound, rows)]
					: [for (arg in args) ExpressionConverter.SubstituteOuter(arg, bound, rows)];
				{expr: ECall({expr: EField(query, method), pos: callee.pos}, prepared), pos: e.pos};

			case _:
				ExprTools.map(e, inner -> PrepareSubqueries(inner, bound, rows));
		}
	}

	/**
		A method called on something in the lambda, where that something is not `Sql`.

		A row's string searched, a query asked a question, a captured list tested — or nothing this
		knows, in which case null, and the call is read as a value the lambda holds.
	**/
	public static function MethodCall(e:Expr, owner:Expr, method:String, args:Array<Expr>, bound:Map<String, Int>,
			rows:Array<Type>):Null<Expr> {
		if (ExpressionConverter.PathOf(owner, bound) != null) {
			return switch method {
				case "contains" | "startsWith" | "endsWith" if (args.length == 1):
					StringOperation(method, owner, args[0], bound, rows);
				case _:
					null;
			}
		}
		if (SubqueryMethods.indexOf(method) >= 0 && IsQuery(owner)) {
			return SubqueryCall(owner, method, args, bound, rows, e.pos);
		}
		if (method == "contains" && args.length == 1) {
			final element = ElementType(owner);
			if (element != null) {
				return InList(args[0], owner, element, false, bound, rows);
			}
		}
		return null;
	}

	static function IsQuery(e:Expr):Bool {
		final type = try Context.typeof(e) catch (_:Dynamic) return false;
		return switch type.follow() {
			case TAbstract(t, _): StringTools.startsWith(t.get().name, "ISelectQuery");
			case TInst(t, _): t.get().name == "SelectQueryImpl";
			case _: false;
		}
	}

	/** What a captured list holds, or null where the expression is not a list. */
	static function ElementType(e:Expr):Null<Type> {
		final type = try Context.typeof(e) catch (_:Dynamic) return null;
		return switch type.follow() {
			case TInst(t, [element]) if (t.get().name == "Array" || t.get().name == "List"): element;
			case _: null;
		}
	}

	static function SubqueryCall(owner:Expr, method:String, args:Array<Expr>, bound:Map<String, Int>,
			rows:Array<Type>, pos:Position):Expr {
		final query = macro(cast $owner : codequery.queries.SelectQueryImpl);
		final value = (index:Int) -> ExpressionConverter.ToSqlExpression(args[index], bound, rows);

		return switch method {
			case "Any" if (args.length == 0):
				macro codequery.sqlexpressions.Expr.exists(codequery.queries.Subquery.Of($query));

			case "Any":
				final narrowed = args[0];
				macro codequery.sqlexpressions.Expr.exists(
					codequery.queries.Subquery.Of(cast $owner.Where($narrowed)));

			// Everything matches only if nothing fails to, which is how SQL is able to ask it at all.
			case "All":
				final failing = Negated(args[0]);
				macro codequery.sqlexpressions.Expr.exists(
					codequery.queries.Subquery.Of(cast $owner.Where($failing)), true);

			case "Contains":
				macro codequery.sqlexpressions.Expr.inQuery(${value(0)}, codequery.queries.Subquery.Of($query));

			case "Sum" | "Max" | "Min" | "Avg":
				final selector = args[0];
				final aggregate = {
					expr: ECall({expr: EField(macro __aggregates, method.toLowerCase()), pos: pos}, [selector]),
					pos: pos
				};
				macro codequery.sqlexpressions.Expr.scalar(
					codequery.queries.Subquery.Of(cast $owner.SelectAggregation(__aggregates -> $aggregate)));

			case "Count":
				macro codequery.sqlexpressions.Expr.scalar(codequery.queries.Subquery.Counting($query));

			case "FirstOrDefault" | "FetchFirst" | "FetchFirstOrDefault":
				macro codequery.sqlexpressions.Expr.scalar(codequery.queries.Subquery.Limited($query, 1));

			case _:
				Context.error('$method gathers the rows as JSON, which this port does not have', pos);
		}
	}

	/** The predicate with its answer turned round: `o -> !(…)`. */
	static function Negated(lambda:Expr):Expr {
		return switch lambda.expr {
			case EFunction(kind, f):
				final body = ExpressionConverter.Unwrap(f.expr);
				final negated = {expr: EUnop(OpNot, false, {expr: EParenthesis(body), pos: body.pos}), pos: body.pos};
				{expr: EFunction(kind, {args: f.args, ret: f.ret, expr: {expr: EReturn(negated), pos: body.pos}}), pos: lambda.pos};
			case _:
				Context.error("All takes a predicate, e.g. o -> o.total > 0", lambda.pos);
		}
	}

	/**
		What `.Any()`, `.Sum(…)` and the rest are when the lambda is typed rather than converted.

		The conversion reads the call as syntax and never lets it run; typing the lambda still has
		to see a method of that name, with the right answer type. So each is a macro that type-checks
		what it was given and answers with a value of that type — one that says, if it is ever
		reached, that the question only means something inside a lambda.
	**/
	public static function Operation(self:Expr, name:String, args:Array<Expr>):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final outside = (type:ComplexType) -> macro(cast codequery.queries.Subquery.Outside($v{name}) : $type);

		return switch name {
			case "Any" if (args.length == 0):
				outside(macro :Bool);
			case "Any" | "All":
				final condition = ExpressionConverter.Convert(args[0], rows);
				macro {
					$condition;
					${outside(macro :Bool)};
				};
			case "Contains":
				final value = args[0];
				macro {
					$value;
					${outside(macro :Bool)};
				};
			case "Sum" | "Max" | "Min":
				final key = ExpressionConverter.ConvertKey(args[0], rows);
				final answers = SelectorType(args[0], rows);
				macro {
					$key;
					${outside(answers)};
				};
			case "Avg":
				final key = ExpressionConverter.ConvertKey(args[0], rows);
				macro {
					$key;
					${outside(macro :Float)};
				};
			case "FirstOrDefault" | "FetchFirst" | "FetchFirstOrDefault":
				outside(rows[0].toComplexType());
			case "ToList":
				outside(TPath({pack: [], name: "Array", params: [TPType(rows[0].toComplexType())]}));
			case _:
				Context.error('$name is not something a query is asked', self.pos);
		}
	}

	/** What a selector answers with, typed against the rows it is written over. */
	static function SelectorType(selector:Expr, rows:Array<Type>):ComplexType {
		final fn = switch selector.expr {
			case EFunction(_, f): f;
			case _: Context.error("Expected a selector, e.g. o -> o.total", selector.pos);
		}
		return ExpressionConverter.ProjectedRow(fn, rows, selector.pos).toComplexType();
	}

	// ---- captured values ------------------------------------------------------------------------------

	/**
		A value the lambda closed over — a variable, a call over one, a member of one. It is not a
		question for the database: it is a value the query already has, so it is read where it stands
		and travels beside the statement as a parameter.
	**/
	public static function Captured(e:Expr):Expr {
		final type = try Context.typeof(e) catch (_:Dynamic) Context.error('Cannot convert to SQL: ${e.toString()}', e.pos);
		return ExpressionConverter.ParameterisedAs(e, type);
	}

	/** The values of a captured list, each as a parameter: `x IN (…)`. */
	static function InList(value:Expr, list:Expr, element:Type, negate:Bool, bound:Map<String, Int>,
			rows:Array<Type>):Expr {
		final factory = ParameterFactory(element, list.pos);
		final tested = ExpressionConverter.ToSqlExpression(value, bound, rows);
		return macro codequery.sqlexpressions.Expr.isIn($tested, [for (item in $list) $factory(item)], $v{negate});
	}

	/** `Sql.isIn(x, list)` where the list is a variable rather than written out. */
	public static function InCapturedList(value:Expr, list:Expr, negate:Bool, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final element = ElementType(list);
		if (element == null) {
			Context.error("Sql.isIn takes the values as a list — written out here, or a captured Array", list.pos);
		}
		return InList(value, list, element, negate, bound, rows);
	}

	/** The `Expr` factory that binds a value of `type` as a parameter. */
	static function ParameterFactory(type:Type, pos:Position):Expr {
		return ExpressionConverter.Factory(switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int"}, _): "paramInt";
			case TAbstract(_.get() => {name: "Float"}, _): "paramFloat";
			case TAbstract(_.get() => {name: "Bool"}, _): "paramBool";
			case TInst(_.get() => {name: "String"}, _): "paramString";
			case TInst(_.get() => {name: "Date"}, _): "paramDate";
			case t: Context.error('${t.toString()} is not something a parameter can hold', pos);
		});
	}

	/** Whether a type is one a column, and so a parameter, can hold. */
	static function IsScalar(type:Type):Bool {
		return switch type.followWithAbstracts() {
			case TAbstract(_.get() => {name: "Int" | "Float" | "Bool"}, _): true;
			case TInst(_.get() => {name: "String" | "Date"}, _): true;
			case _: false;
		}
	}

	// ---- the operators, where they mean more than the operator ---------------------------------------

	/**
		A binary operator that is more than the operator says, or null where it is not:

		- `&&` and `||` where one side is already decided — a captured flag, a guard on a captured
		  list — fold to the other side, which is not converted at all, as C# would not evaluate it;
		- `list == null` on a captured list is answered while the query is built, since a list has no
		  SQL form to be asked about;
		- `!=` against a column that can hold NULL becomes `IS DISTINCT FROM`, so that a null row is
		  different, as it is in the language the lambda is written in.
	**/
	public static function Binary(op:Binop, left:Expr, right:Expr, bound:Map<String, Int>, rows:Array<Type>):Null<Expr> {
		return switch op {
			case OpBoolAnd | OpBoolOr:
				final l = ExpressionConverter.ToSqlExpression(left, bound, rows);
				final r = ExpressionConverter.ToSqlExpression(right, bound, rows);
				final factory = ExpressionConverter.Factory(op.match(OpBoolAnd) ? "andAlso" : "orElse");
				macro $factory($l, () -> $r);

			case OpEq | OpNotEq:
				final folded = FoldedNullTest(op, left, right, bound);
				if (folded != null) {
					return folded;
				}
				if (op.match(OpNotEq) && !IsNullLiteral(left) && !IsNullLiteral(right)
					&& (NullableColumn(left, bound, rows) || NullableColumn(right, bound, rows))) {
					final l = ExpressionConverter.ToSqlExpression(left, bound, rows);
					final r = ExpressionConverter.ToSqlExpression(right, bound, rows);
					return macro codequery.sqlexpressions.Expr.isDistinctFrom($l, $r);
				}
				null;

			case _:
				null;
		}
	}

	static function IsNullLiteral(e:Expr):Bool {
		return ExpressionConverter.Unwrap(e).expr.match(EConst(CIdent("null")));
	}

	/**
		`list == null` where the list is a value the query holds: answered here, as a constant. A
		scalar keeps its test — the database can hold one, and `IS NULL` reads the same either way.
	**/
	static function FoldedNullTest(op:Binop, left:Expr, right:Expr, bound:Map<String, Int>):Null<Expr> {
		final other = IsNullLiteral(right) ? left : (IsNullLiteral(left) ? right : null);
		if (other == null || ExpressionConverter.PathOf(other, bound) != null || ExpressionConverter.IsSqlExpression(other)) {
			return null;
		}
		final type = try Context.typeof(other) catch (_:Dynamic) return null;
		if (IsScalar(type)) {
			return null;
		}
		return op.match(OpEq)
			? macro codequery.sqlexpressions.Expr.constBool($other == null)
			: macro codequery.sqlexpressions.Expr.constBool($other != null);
	}

	/**
		Whether an expression reads a column that can hold NULL — the schema's own answer, the one
		the migration is written with: a `Null<T>`, or a string not marked `@columnNullable(false)`.
	**/
	static function NullableColumn(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Bool {
		final reached = ExpressionConverter.PathOf(e, bound);
		if (reached == null) {
			return false;
		}
		var row = rows[reached.row];
		var field:Null<ClassField> = null;
		for (step in reached.path) {
			field = ExpressionConverter.FieldNamed(row, step);
			if (field == null) {
				return false;
			}
			row = field.type;
		}
		return field != null && IsNullable(field);
	}

	static function IsNullable(field:ClassField):Bool {
		final stated = switch field.meta.extract("columnNullable") {
			case [{params: [{expr: EConst(CIdent(v))}]}]: v == "true";
			case _: null;
		}
		if (stated != null) {
			return stated;
		}
		return switch field.type {
			case TType(t, _) if (t.get().name == "Null"): true;
			case TAbstract(t, _) if (t.get().name == "Null"): true;
			case TInst(t, _) if (t.get().name == "String"): true;
			case _: false;
		}
	}

	/** `!x`, folded where `x` is a captured flag and so already decided. */
	public static function Negation(operand:Expr):Expr {
		return switch operand.expr {
			case ECall(factory = {expr: EField(_, "constBool" | "paramBool", _)}, [flag]):
				{expr: ECall(factory, [macro !$flag]), pos: operand.pos};
			case _:
				macro codequery.sqlexpressions.Expr.not($operand);
		}
	}

	// ---- strings ----------------------------------------------------------------------------------------

	static function StringOperation(method:String, operand:Expr, pattern:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final kind = switch method {
			case "contains": "Contains";
			case "startsWith": "StartsWith";
			case _: "EndsWith";
		}
		final type = macro $p{["codequery", "sqlexpressions", "StringOperationType", kind]};
		final searched = ExpressionConverter.ToSqlExpression(operand, bound, rows);
		final term = ExpressionConverter.ToSqlExpression(pattern, bound, rows);
		return macro codequery.sqlexpressions.Expr.stringOp($type, $searched, $term);
	}

	/**
		`Sql.likeAll(row, term)` — the term searched for in every column of the row but its key, as
		C#'s `DbFunctions.LikeAll` does. A text column is searched as it stands; anything else is
		cast to text first. The arms are OR-ed left to right, in the order the entity declares them.
	**/
	public static function LikeAll(row:Expr, term:Expr, bound:Map<String, Int>, rows:Array<Type>, pos:Position):Expr {
		final index = switch ExpressionConverter.Unwrap(row).expr {
			case EConst(CIdent(name)) if (bound.exists(name)): bound[name];
			case _: Context.error("Sql.likeAll takes the row itself, e.g. Sql.likeAll(a, term)", row.pos);
		}
		final entity = switch rows[index].follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', row.pos);
		}
		final arms:Array<Expr> = [];
		for (field in entity.fields.get()) {
			if (!IsColumn(field) || IsKey(field) || !IsValue(field.type)) {
				continue;
			}
			final column = ExpressionConverter.ColumnFor(rows[index], index, [field.name], pos);
			final operand = IsText(field.type)
				? column
				: macro codequery.sqlexpressions.Expr.castTo($column, codequery.sqlexpressions.SqlType.SqlText);
			arms.push(macro codequery.sqlexpressions.Expr.stringOp(
				codequery.sqlexpressions.StringOperationType.Contains, $operand, __term));
		}
		if (arms.length == 0) {
			Context.error('${entity.name} has no column to search', pos);
		}

		var chain = arms[0];
		for (arm in arms.slice(1)) {
			chain = macro codequery.sqlexpressions.Expr.or($chain, $arm);
		}
		final searched = ExpressionConverter.ToSqlExpression(term, bound, rows);
		return macro {
			final __term = $searched;
			$chain;
		};
	}

	/** A public instance variable is a column — the rule `ColumnsBuilder` applies. */
	static function IsColumn(field:ClassField):Bool {
		return field.isPublic && switch field.kind {
			case FVar(AccNormal | AccNo, _): true;
			case _: false;
		}
	}

	/** The key is `id`, or whatever says `@primaryKey` — the rule the schema applies. */
	static function IsKey(field:ClassField):Bool {
		return field.name == "id" || field.meta.has("primaryKey");
	}

	/** A value rather than a nested object: what a column can hold on its own. */
	static function IsValue(type:Type):Bool {
		return switch type.follow() {
			case TInst(t, _):
				final path = t.get().pack.concat([t.get().name]).join(".");
				path == "String" || path == "Date";
			case _:
				true;
		}
	}

	static function IsText(type:Type):Bool {
		return switch type.followWithAbstracts() {
			case TInst(_.get() => {name: "String"}, _): true;
			case _: false;
		}
	}

	// ---- CASE written out -----------------------------------------------------------------------------

	static function IsDbCase(e:Expr):Bool {
		return switch e.expr {
			case EConst(CIdent("DbCase")): true;
			case EField({expr: EConst(CIdent("codequery"))}, "DbCase", _): true;
			case _: false;
		}
	}

	/** Whether a call is the end of a `DbCase.When(…)…` or `DbCase.On(…)…` chain. */
	public static function IsCaseChain(e:Expr):Bool {
		var walk = ExpressionConverter.Unwrap(e);
		while (true) {
			switch walk.expr {
				case ECall({expr: EField(root, "When" | "On", _)}, _) if (IsDbCase(root)):
					return true;
				case ECall({expr: EField(inner, "When" | "Else" | "End", _)}, _):
					walk = ExpressionConverter.Unwrap(inner);
				case _:
					return false;
			}
		}
	}

	/** The chain read from the outside in, so the arms are collected in the order written. */
	public static function CaseChain(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final convert = (x:Expr) -> ExpressionConverter.ToSqlExpression(x, bound, rows);

		var operand:Null<Expr> = null;
		var otherwise:Null<Expr> = null;
		final branches:Array<{when:Expr, then:Expr}> = [];

		var walk = ExpressionConverter.Unwrap(e);
		while (true) {
			switch walk.expr {
				case ECall({expr: EField(root, "When", _)}, [when, then]) if (IsDbCase(root)):
					branches.unshift({when: when, then: then});
					break;
				case ECall({expr: EField(root, "On", _)}, [tested]) if (IsDbCase(root)):
					operand = tested;
					break;
				case ECall({expr: EField(inner, "When", _)}, [when, then]):
					branches.unshift({when: when, then: then});
					walk = ExpressionConverter.Unwrap(inner);
				case ECall({expr: EField(inner, "Else", _)}, [fallback]):
					otherwise = fallback;
					walk = ExpressionConverter.Unwrap(inner);
				case ECall({expr: EField(inner, "End", _)}, []):
					walk = ExpressionConverter.Unwrap(inner);
				case _:
					Context.error("A CASE is DbCase.When(…).When(…).Else(…), or DbCase.On(x).When(…).End()", walk.pos);
			}
		}

		final arms = {
			expr: EArrayDecl([
				for (branch in branches)
					macro codequery.sqlexpressions.Expr.branch(${convert(branch.when)}, ${convert(branch.then)})
			]),
			pos: e.pos
		};
		final fallback = otherwise == null ? macro null : convert(otherwise);
		return operand == null
			? macro codequery.sqlexpressions.Expr.caseWhen($arms, $fallback)
			: macro codequery.sqlexpressions.Expr.simpleCase(${convert(operand)}, $arms, $fallback);
	}

	// ---- the correlation of a WHERE EXISTS -----------------------------------------------------------

	/**
		The correlation of `WhereExists(table, (c, o) -> o.customerId == c.id)`: written over the
		query's rows and then the table's, converted as a predicate over the table alone, with the
		query's rows read as the statement outside — the same shape every other subquery has.
	**/
	public static function Correlation(correlation:Expr, outer:Array<Type>, table:Type):Expr {
		final lambda = ExpressionConverter.ResolveLambda(correlation);
		final fn = switch lambda.expr {
			case EFunction(_, f) if (f.args.length == outer.length + 1): f;
			case _: Context.error('Expected a correlation over ${outer.length + 1} rows, the table\'s last', correlation.pos);
		}

		final bound = new Map<String, Int>();
		for (index in 0...outer.length) {
			bound.set(fn.args[index].name, index);
		}
		final body = ExpressionConverter.SubstituteOuter(ExpressionConverter.Unwrap(fn.expr), bound, outer);
		final inner = {
			expr: EFunction(FAnonymous, {args: [fn.args[outer.length]], ret: null, expr: {expr: EReturn(body), pos: body.pos}}),
			pos: lambda.pos
		};
		return ExpressionConverter.Convert(inner, [table]);
	}

	/**
		The outer row read where a lateral's body wants a value now — a row count, an offset. There
		is no SQL for that: a lateral can name the outer row's columns, not shape itself by them.
	**/
	public static function RefuseOuterValue(e:Expr):Void {
		switch ExpressionConverter.Unwrap(e).expr {
			case ECast({expr: ECall({expr: EField(_, "outer", _)}, _)}, _):
				Context.error("The outer row is read as a value here rather than translated: a lateral's query can "
					+ "name the outer row's columns in its clauses, not use them to shape itself", e.pos);
			case _:
		}
	}

	// ---- a clause only sometimes wanted -----------------------------------------------------------------

	/**
		`Conditional(condition, q -> q.Where(…))` — the same query as an `if` around the clause, said
		in the chain. The lambda is not read at all where the condition does not hold, and a lambda
		that is not there is a mistake rather than a no-op.
	**/
	public static function Conditional(self:Expr, condition:Expr, then:Expr, otherwise:Null<Expr>):Expr {
		final type = Context.typeof(self).toComplexType();
		final fallback = ExpressionConverter.Omitted(otherwise) ? macro null : otherwise;
		return macro {
			final query:$type = $self;
			final then:$type->$type = $then;
			if (then == null) {
				throw "Conditional takes a lambda to apply where the condition holds; this one is null";
			}
			final otherwise:Null<$type->$type> = $fallback;
			$condition ? then(query) : (otherwise == null ? query : otherwise(query));
		};
	}
	#end
}
