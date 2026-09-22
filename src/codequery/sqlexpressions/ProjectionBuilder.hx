package codequery.sqlexpressions;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
#end

/**
	What a projection lambda selects, as columns: one list, flat, each column knowing where in the
	answer it belongs. The one mechanism behind `Select` and `Reduce` alike — they differ in what
	they do with the result, not in how a row is read.

	A projection is written as a tree. `{unit: u, data: {col: b.id}}` names a whole joined row and
	an object built on the spot, and neither is a value a column could hold. A result set is flat, so
	the tree is flattened here: every leaf becomes a column named along the path that reaches it —
	`unit_id`, `data_col` — and keeps that path, which is what lets a later clause name a leaf again.

	C# does this at runtime over an expression tree. Here, for a `Select` compiled to a callback,
	the tree is emitted as it was written with each leaf converted — `{price: b.price.zar, unit: u}`
	— and `RowProjection` flattens what the callback answers with when the query runs, spreading a
	whole row over the columns it hands out. Converted inline — an aggregate's selector, a subquery
	— the flattening happens here, over syntax, by reading the entity's fields.
**/
class ProjectionBuilder {
	/** `new Date(…)` makes a value, not a row of members: it converts as an expression. */
	static function BuildsAValue(e:Expr):Bool {
		return switch e.expr {
			case ENew({name: "Date"}, _): true;
			case _: false;
		}
	}

	#if macro
	/**
		The selection `body` describes: a `ProjectionSqlExpression` of flattened members where it
		builds a row, the value itself where it is one — `Select(b -> b.id)` asks for a column, not
		for a row of one — and every column of a row where it names one whole.
	**/
	public static function Build(body:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final e = ExpressionConverter.Unwrap(body);
		if (ExpressionConverter.callback != null) {
			return Tree(e, bound, rows);
		}
		switch e.expr {
			// A structure names each member; the names are what the columns come back as.
			case EObjectDecl(_) | ENew(_, _) if (!BuildsAValue(e)):
				return Projection(Flattened([], e, bound, rows), e.pos);

			// `cast({…}, Row)` — a structure built as a row type of its own, which names its columns.
			case ECast({expr: EObjectDecl(_) | EParenthesis({expr: EObjectDecl(_)})}, type) if (type != null):
				return Projection(Flattened([], e, bound, rows), e.pos);

			// A row on its own selects that row's columns.
			case EConst(CIdent(name)) if (bound.exists(name)):
				final index = bound[name];
				return macro new codequery.sqlexpressions.AllColumnsSqlExpression(
					codequery.sqlexpressions.ParameterSqlSource.At($v{index}));

			// A row reached through another — `f -> f.u` — is that row and nothing else, so its
			// columns keep their own names.
			case EField(_, _, _):
				final reached = ExpressionConverter.PathOf(e, bound);
				if (reached != null) {
					final held = ExpressionConverter.MemberTypeOf(reached.path, rows[reached.row], e.pos);
					if (IsObject(held)) {
						return Projection(Flattened([], e, bound, rows), e.pos);
					}
				}

			case _:
		}

		// One expression, naming nothing — `a -> a.name`, which C# answers with a query of that value.
		return ExpressionConverter.ToSqlExpression(e, bound, rows);
	}

	static function Projection(members:Array<Expr>, pos:Position):Expr {
		final list = {expr: EArrayDecl(members), pos: pos};
		return macro new codequery.sqlexpressions.ProjectionSqlExpression($list);
	}

	// ---- the callback's answer: the tree as written ---------------------------------------------------

	/**
		What a callback answers with: a structure as it was written, each value converted; a row
		named whole as the columns the callback was handed, which the query reads as all of them; a
		lone expression as itself. `RowProjection` flattens it when the query runs.
	**/
	static function Tree(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		switch e.expr {
			case EObjectDecl(_) | ENew(_, _) if (!BuildsAValue(e)):
				return Literal(e, bound, rows);
			case ECast({expr: EObjectDecl(_) | EParenthesis({expr: EObjectDecl(_)})}, type) if (type != null):
				return Literal(e, bound, rows);

			// A row on its own. An entity's is the columns handed in, and the query selects all of
			// them; a row a projection built is one already, so its columns are named by position.
			case EConst(CIdent(name)) if (bound.exists(name)):
				final index = bound[name];
				if (ExpressionConverter.IsStructure(rows[index])) {
					return macro new codequery.sqlexpressions.AllColumnsSqlExpression(
						codequery.sqlexpressions.ParameterSqlSource.At($v{index}));
				}
				return macro $i{ExpressionConverter.CallbackName(index)};

			// A row reached through another — `f -> f.u` — is that row and nothing else.
			case EField(_, _, _):
				final reached = ExpressionConverter.PathOf(e, bound);
				if (reached != null) {
					final held = ExpressionConverter.MemberTypeOf(reached.path, rows[reached.row], e.pos);
					if (IsObject(held)) {
						return ExpressionConverter.ColumnFor(rows[reached.row], reached.row, reached.path, e.pos);
					}
				}

			case _:
		}
		return ExpressionConverter.ToSqlExpression(e, bound, rows);
	}

	/** A structure written out, as a structure of converted values; nested ones stay nested. */
	static function Literal(e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final e = ExpressionConverter.Unwrap(e);
		final fields:Array<ObjectField> = [];
		switch e.expr {
			case EObjectDecl(members):
				for (member in members) {
					fields.push({field: member.field, expr: Value(member.expr, bound, rows)});
				}

			// Built as a row type of its own, so the members are named as that type names its columns.
			case ECast(inner, type) if (type != null):
				final members = switch ExpressionConverter.Unwrap(inner).expr {
					case EObjectDecl(members): members;
					case _: return Value(inner, bound, rows);
				}
				final names = ColumnNamesOf(Context.resolveType(type, e.pos), e.pos);
				for (member in members) {
					final named = names.exists(member.field) ? names[member.field] : member.field;
					fields.push({field: named, expr: Value(member.expr, bound, rows)});
				}

			// A constructor call: its arguments are the members, named as the constructor names them.
			case ENew(typePath, args):
				final names = ConstructorArguments(typePath, e.pos);
				for (index => arg in args) {
					fields.push({field: index < names.length ? names[index] : 'arg$index', expr: Value(arg, bound, rows)});
				}

			case _:
				return Value(e, bound, rows);
		}
		final literal = {expr: EObjectDecl(fields), pos: e.pos};
		// A result set is ordered as the structure was written. PHP keeps an object's fields in that
		// order; eval orders them by name, so there the order is written on the structure.
		if (!Context.defined("eval")) {
			return literal;
		}
		final names = {expr: EArrayDecl([for (field in fields) macro $v{field.field}]), pos: e.pos};
		return macro codequery.sqlexpressions.RowProjection.Ordered($names, $literal);
	}

	/**
		One value of a structure: a structure within it stays one; a whole row, or an object reached
		through one, is the columns the callback was handed, which the query spreads out; anything
		else is the one expression it looks like.
	**/
	static function Value(value:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		final e = ExpressionConverter.Unwrap(value);
		switch e.expr {
			case EObjectDecl(_) | ENew(_, _) if (!BuildsAValue(e)):
				return Literal(e, bound, rows);
			case ECast(_, type) if (type != null):
				return Literal(e, bound, rows);
			case EConst(CIdent(name)) if (bound.exists(name)):
				return macro $i{ExpressionConverter.CallbackName(bound[name])};
			case EField(_, _, _):
				final reached = ExpressionConverter.PathOf(e, bound);
				if (reached != null) {
					final held = ExpressionConverter.MemberTypeOf(reached.path, rows[reached.row], e.pos);
					if (IsObject(held)) {
						return ExpressionConverter.ColumnFor(rows[reached.row], reached.row, reached.path, e.pos);
					}
				}
			case _:
		}
		return ExpressionConverter.ToSqlExpression(e, bound, rows);
	}

	/**
		One projected value as the members it really is, each beneath `path`. A value holding a row
		of its own — an object built in the projection, a whole joined row, a row an earlier
		projection named — is that row's columns, each named under the member carrying it; anything
		else is already the one column it looks like.
	**/
	static function Flattened(path:Array<String>, value:Expr, bound:Map<String, Int>, rows:Array<Type>):Array<Expr> {
		final e = ExpressionConverter.Unwrap(value);
		final into:Array<Expr> = [];

		switch e.expr {
			case EObjectDecl(fields):
				for (field in fields) {
					for (member in Flattened(path.concat([field.field]), field.expr, bound, rows)) {
						into.push(member);
					}
				}
				return into;

			// Built as a row type of its own, so the members are named as that type names its columns.
			case ECast(inner, type) if (type != null):
				final fields = switch ExpressionConverter.Unwrap(inner).expr {
					case EObjectDecl(fields): fields;
					case _: return [Leaf(path, e, bound, rows)];
				}
				final names = ColumnNamesOf(Context.resolveType(type, e.pos), e.pos);
				for (field in fields) {
					final named = names.exists(field.field) ? names[field.field] : field.field;
					for (member in Flattened(path.concat([named]), field.expr, bound, rows)) {
						into.push(member);
					}
				}
				return into;

			// A constructor call: its arguments are the members, named as the constructor names them.
			case ENew(typePath, args) if (!BuildsAValue(e)):
				final names = ConstructorArguments(typePath, e.pos);
				for (index => arg in args) {
					final name = index < names.length ? names[index] : 'arg$index';
					for (member in Flattened(path.concat([name]), arg, bound, rows)) {
						into.push(member);
					}
				}
				return into;

			// A whole joined row: every column of it, under the member carrying it.
			case EConst(CIdent(name)) if (bound.exists(name)):
				final index = bound[name];
				for (leaf in Leaves(rows[index], [], [])) {
					final column = ExpressionConverter.ColumnFor(rows[index], index, leaf.fields, e.pos);
					into.push(Member(path.concat(leaf.names), column, e.pos));
				}
				return into;

			// A row reached through a member — `f.u` after a reduce, `x.unit` over a projection.
			case EField(_, _, _):
				final reached = ExpressionConverter.PathOf(e, bound);
				if (reached != null) {
					final row = rows[reached.row];
					final held = ExpressionConverter.MemberTypeOf(reached.path, row, e.pos);
					if (IsObject(held)) {
						for (leaf in Leaves(held, [], [])) {
							final column = ExpressionConverter.ColumnFor(row, reached.row, reached.path.concat(leaf.fields), e.pos);
							into.push(Member(path.concat(leaf.names), column, e.pos));
						}
						return into;
					}
				}

			case _:
		}

		return [Leaf(path, e, bound, rows)];
	}

	static function Leaf(path:Array<String>, e:Expr, bound:Map<String, Int>, rows:Array<Type>):Expr {
		return Member(path, ExpressionConverter.ToSqlExpression(e, bound, rows), e.pos);
	}

	static function Member(path:Array<String>, expression:Expr, pos:Position):Expr {
		final steps = {expr: EArrayDecl([for (step in path) macro $v{step}]), pos: pos};
		return macro codequery.sqlexpressions.ProjectionMember.Along($steps, $expression);
	}

	/** Whether a member holds a row rather than a value — a class that is not a string or a date, or a structure. */
	public static function IsObject(type:Type):Bool {
		return switch type.follow() {
			case TInst(t, _):
				final held = t.get();
				final name = held.pack.concat([held.name]).join(".");
				name != "String" && name != "Date";
			case TAnonymous(_): true;
			case _: false;
		}
	}

	/**
		The columns a row type spreads over, however deep its objects go: the fields to walk to reach
		each, and the names — an entity's column names, a structure's field names — that name it.
	**/
	public static function Leaves(type:Type, fields:Array<String>, names:Array<String>):Array<Leaf> {
		final leaves:Array<Leaf> = [];
		switch type.follow() {
			case TInst(t, _):
				for (field in t.get().fields.get()) {
					if (!field.isPublic || !field.kind.match(FVar(AccNormal | AccNo, _))) {
						continue;
					}
					final step = fields.concat([field.name]);
					final named = names.concat([ColumnsBuilder.ColumnNameOf(field)]);
					if (IsObject(field.type)) {
						for (leaf in Leaves(field.type, step, named)) {
							leaves.push(leaf);
						}
					} else {
						leaves.push({fields: step, names: named, type: field.type});
					}
				}
			case TAnonymous(a):
				for (field in a.get().fields) {
					final step = fields.concat([field.name]);
					final named = names.concat([field.name]);
					if (IsObject(field.type)) {
						for (leaf in Leaves(field.type, step, named)) {
							leaves.push(leaf);
						}
					} else {
						leaves.push({fields: step, names: named, type: field.type});
					}
				}
			case _:
		}
		return leaves;
	}

	/** A row type's column names by field, for the members built as one of it. */
	static function ColumnNamesOf(type:Type, pos:Position):Map<String, String> {
		final names = new Map<String, String>();
		switch type.follow() {
			case TInst(t, _):
				for (field in t.get().fields.get()) {
					names.set(field.name, ColumnsBuilder.ColumnNameOf(field));
				}
			case _:
		}
		return names;
	}

	/** The names a class's constructor gives its arguments, in order. */
	static function ConstructorArguments(typePath:TypePath, pos:Position):Array<String> {
		final type = Context.resolveType(TPath(typePath), pos);
		return switch type.follow() {
			case TInst(t, _):
				final constructor = t.get().constructor;
				if (constructor == null) {
					Context.error('${t.get().name} has no constructor to project into', pos);
				}
				switch constructor.get().type.follow() {
					case TFun(args, _): [for (arg in args) arg.name];
					case _: [];
				}
			case t: Context.error('${t.toString()} is not a class a projection can construct', pos);
		}
	}
	#end
}

#if macro
/** One column a row type spreads over: the fields walked to reach it, the names that name it, and what it holds. */
typedef Leaf = {fields:Array<String>, names:Array<String>, type:Type};
#end
