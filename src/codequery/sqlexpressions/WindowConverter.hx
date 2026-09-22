package codequery.sqlexpressions;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
#end

/**
	Converts what `DbAggregation` and `Window` say inside a projection — an aggregate or a window
	function read beside a row's own columns:

	```haxe
	DbAggregation.sum(t.amount).filter(t.amount > 0).over(null, t.orderDate)
	Window.rowNumber(w -> w.PartitionBy(b.authorId).OrderByDesc(b.revenue))
	```

	`ExpressionConverter` hands it any call it does not know, and it answers with the expression
	building the node, or null where the call is not one of these. The values in the chain are the
	projection's own — a column, a constant, an expression over the row — so they are converted by
	the converter that was already reading the projection, handed in as `value`.
**/
class WindowConverter {
	#if macro
	/**
		The query a projection is being written for, so `over(w)` can reach the window it names.
		Set by whoever converts a projection, for as long as the conversion takes.
	**/
	public static var CurrentQuery:Null<Expr> = null;

	/** The chain as its node, or null where `e` is not a `DbAggregation` or `Window` call. */
	public static function Convert(e:Expr, bound:Map<String, Int>, rows:Array<Type>, value:Expr->Expr):Null<Expr> {
		final chain = Chain(e);
		if (chain == null) {
			return null;
		}
		return switch chain.root {
			case "DbAggregation": Aggregated(chain, bound, rows, value, e.pos);
			case _: Windowed(chain, value, e.pos);
		}
	}

	/** `Window.<fn>(…, spec)`. */
	static function Windowed(chain:Chain, value:Expr->Expr, pos:Position):Expr {
		if (chain.calls.length > 0) {
			Context.error('Window.${chain.fn}(…) is the value itself; nothing follows it', pos);
		}
		final args = chain.args;
		final spec = args[args.length - 1];
		final leading = args.slice(0, args.length - 1);

		final expected = switch chain.fn {
			case "rowNumber" | "rank" | "denseRank" | "percentRank" | "cumeDist": 0;
			case "ntile" | "firstValue" | "lastValue": 1;
			case "lag" | "lead" | "nthValue": 2;
			case other: Context.error('Window.$other is not a window function', pos);
		}
		if (leading.length != expected) {
			Context.error('Window.${chain.fn} takes $expected argument(s) before its window', pos);
		}

		final name = switch chain.fn {
			case "rowNumber": "RowNumber";
			case "rank": "Rank";
			case "denseRank": "DenseRank";
			case "ntile": "Ntile";
			case "lag": "Lag";
			case "lead": "Lead";
			case "firstValue": "FirstValue";
			case "lastValue": "LastValue";
			case "nthValue": "NthValue";
			case "percentRank": "PercentRank";
			case _: "CumeDist";
		}
		final arguments = {expr: EArrayDecl(leading.map(value)), pos: pos};
		final over = Definition(spec, value);
		return macro new codequery.sqlexpressions.WindowFunctionExpression(
			$p{["codequery", "sqlexpressions", "WindowFunction", name]}, $arguments).OverDefinition($over);
	}

	/** `DbAggregation.<fn>(…)`, then `.filter(…)`, `.distinct()` and `.over(…)` in any order. */
	static function Aggregated(chain:Chain, bound:Map<String, Int>, rows:Array<Type>, value:Expr->Expr, pos:Position):Expr {
		if (chain.fn == "distinct") {
			if (chain.calls.length > 0) {
				Context.error("DbAggregation.distinct(x) is the DISTINCT keyword in front of x; nothing follows it", pos);
			}
			return macro codequery.sqlexpressions.Expr.distinct(${value(chain.args[0])});
		}

		final kind = switch chain.fn {
			case "sum": "Sum";
			case "avg": "Avg";
			case "min": "Min";
			case "max": "Max";
			case "count" | "countValues": "Count";
			case other: Context.error('DbAggregation.$other is not an aggregate', pos);
		}
		final type = macro $p{["codequery", "sqlexpressions", "AggregateType", kind]};
		var aggregate = chain.fn == "count"
			? macro new codequery.sqlexpressions.AggregateSqlExpression($type)
			: macro new codequery.sqlexpressions.AggregateSqlExpression($type, ${value(chain.args[0])});

		var windowed = false;
		for (call in chain.calls) {
			switch call.name {
				case "filter":
					aggregate = macro $aggregate.Filtered(${value(call.args[0])});
				case "distinct":
					aggregate = macro $aggregate.Distinctly();
				case "over":
					windowed = true;
					aggregate = Over(aggregate, call.args, bound, rows, value, pos);
				case other:
					Context.error('An aggregate is filtered, made distinct and given a window; $other is none of them', pos);
			}
		}

		// SQL takes many rows and yields one, so an aggregate can only sit beside ordinary columns if
		// it is computed per row — which is what a window is. Refused where the statement is rendered.
		return windowed ? aggregate : macro new codequery.sqlexpressions.UnfinishedAggregateSqlExpression($aggregate);
	}

	/** The forms of `over`: nothing, a partition and an ordering, a window the query named, a spec. */
	static function Over(aggregate:Expr, args:Array<Expr>, bound:Map<String, Int>, rows:Array<Type>, value:Expr->Expr,
			pos:Position):Expr {
		switch args.length {
			case 0:
				return macro $aggregate.OverDefinition(new codequery.sqlexpressions.WindowDefinition([], []));

			case 2:
				final partitionBy = IsNull(args[0]) ? macro [] : macro [${value(args[0])}];
				final orderBy = IsNull(args[1])
					? macro []
					: macro [new codequery.sqlexpressions.OrderByExpression(${value(args[1])}, true)];
				return macro $aggregate.OverDefinition(
					new codequery.sqlexpressions.WindowDefinition($partitionBy, $orderBy));

			case 1:
				final only = Unwrap(args[0]);
				if (only.expr.match(EFunction(_, _))) {
					return macro $aggregate.OverDefinition(${Definition(only, value)});
				}
				final named = switch only.expr {
					case EConst(CIdent(name)) if (bound.exists(name) && IsWindow(rows[bound[name]])): bound[name];
					case _: Context.error("over() takes a window this query has defined, or a spec written out here", only.pos);
				}
				// In a callback the window arrives as the parameter naming it; inline it is read off
				// the query being projected.
				final parameter = ExpressionConverter.CallbackName(named);
				if (parameter != null) {
					return macro $aggregate.OverWindow($i{parameter});
				}
				if (CurrentQuery == null) {
					Context.error("A named window can only be read in a projection", only.pos);
				}
				final query = CurrentQuery;
				return macro $aggregate.OverWindow(codequery.queries.SelectQueryImpl.WindowOf($query, $v{named}));

			case _:
				return Context.error("over() takes nothing, a window, a spec, or a partition key and an ordering", pos);
		}
	}

	/** Whether a row a lambda is written over is a window rather than an entity. */
	public static function IsWindow(row:Type):Bool {
		return switch row.follow() {
			case TInst(t, _): t.get().name == "INamedWindow" && t.get().pack.join(".") == "codequery";
			case _: false;
		}
	}

	/**
		A spec written out — `w -> w.PartitionBy(a, b).OrderByDesc(c).RowsBetween(…)` — as the
		expression building its `WindowDefinition`.
	**/
	static function Definition(spec:Expr, value:Expr->Expr):Expr {
		final fn = switch Unwrap(spec).expr {
			case EFunction(_, f) if (f.args.length == 1): f;
			case _: Context.error("Expected a window spec, e.g. w -> w.PartitionBy(r.id)", spec.pos);
		}

		final partitionBy:Array<Expr> = [];
		final orderBy:Array<Expr> = [];
		final frame:Array<Expr> = [];
		Walk(Unwrap(fn.expr), fn.args[0].name, value, partitionBy, orderBy, frame);

		final partitions = {expr: EArrayDecl(partitionBy), pos: spec.pos};
		final orderings = {expr: EArrayDecl(orderBy), pos: spec.pos};
		final framed = frame.length == 0 ? macro null : frame[0];
		return macro new codequery.sqlexpressions.WindowDefinition($partitions, $orderings, $framed);
	}

	/** The chain is read from the outside in, so the terms are collected in the order written. */
	static function Walk(e:Expr, spec:String, value:Expr->Expr, partitionBy:Array<Expr>, orderBy:Array<Expr>,
			frame:Array<Expr>):Void {
		switch Unwrap(e).expr {
			case EConst(CIdent(name)) if (name == spec):
				return;

			case ECall({expr: EField(owner, call, _)}, args):
				Walk(owner, spec, value, partitionBy, orderBy, frame);
				switch call {
					case "PartitionBy":
						for (key in args) {
							partitionBy.push(value(key));
						}
					case "OrderBy" | "OrderByDesc":
						final ascending = call == "OrderBy";
						final nulls = args.length > 1 ? args[1] : macro codequery.sqlexpressions.NullsOrdering.Default;
						orderBy.push(macro new codequery.sqlexpressions.OrderByExpression(${value(args[0])}, $v{ascending}, $nulls));
					case "RowsBetween" | "RangeBetween":
						final kind = macro $p{["codequery", "sqlexpressions", "FrameKind", call == "RowsBetween" ? "Rows" : "Range"]};
						frame.push(macro new codequery.sqlexpressions.WindowFrame($kind, ${args[0]}, ${args[1]}));
					case _:
						Context.error('A window is partitioned, ordered and framed; $call is none of them', e.pos);
				}

			case _:
				Context.error('Expected a window spec built on "$spec", not ${e.toString()}', e.pos);
		}
	}

	/**
		A call chain rooted at `DbAggregation` or `Window`, flattened: the root's own call, then
		what was called on it, outermost last. Null for anything else.
	**/
	static function Chain(e:Expr):Null<Chain> {
		final calls:Array<{name:String, args:Array<Expr>}> = [];
		var walk = Unwrap(e);
		while (true) {
			switch walk.expr {
				case ECall({expr: EField(owner, name, _)}, args):
					final root = RootOf(Unwrap(owner));
					if (root != null) {
						return {root: root, fn: name, args: args, calls: calls};
					}
					calls.unshift({name: name, args: args});
					walk = Unwrap(owner);
				case _:
					return null;
			}
		}
	}

	static function RootOf(owner:Expr):Null<String> {
		return switch owner.expr {
			case EConst(CIdent(name)) if (name == "DbAggregation" || name == "Window"): name;
			case EField({expr: EConst(CIdent("codequery"))}, name, _) if (name == "DbAggregation" || name == "Window"): name;
			case _: null;
		}
	}

	static function IsNull(e:Expr):Bool {
		return Unwrap(e).expr.match(EConst(CIdent("null")));
	}

	static function Unwrap(e:Expr):Expr {
		return switch e.expr {
			case EParenthesis(inner): Unwrap(inner);
			case ECheckType(inner, _): Unwrap(inner);
			case EMeta(_, inner): Unwrap(inner);
			case EBlock([inner]): Unwrap(inner);
			case EReturn(inner) if (inner != null): Unwrap(inner);
			case _: e;
		}
	}
	#end
}

#if macro
private typedef Chain = {root:String, fn:String, args:Array<Expr>, calls:Array<{name:String, args:Array<Expr>}>};
#end
