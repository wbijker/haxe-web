package suites;

import codequery.Query;
import codequery.queries.ISelectQuery8;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;
using codequery.testing.SourceAccess;

@tableName("t1")
class WideR1 {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

@tableName("t2")
class WideR2 {
	public var id:Int = 0;
	public var r1Id:Int = 0;

	public function new() {}
}

@tableName("t3")
class WideR3 {
	public var id:Int = 0;
	public var r2Id:Int = 0;

	public function new() {}
}

@tableName("t4")
class WideR4 {
	public var id:Int = 0;
	public var r3Id:Int = 0;

	public function new() {}
}

@tableName("t5")
class WideR5 {
	public var id:Int = 0;
	public var r4Id:Int = 0;

	public function new() {}
}

@tableName("t6")
class WideR6 {
	public var id:Int = 0;
	public var r5Id:Int = 0;

	public function new() {}
}

@tableName("t7")
class WideR7 {
	public var id:Int = 0;
	public var r6Id:Int = 0;

	public function new() {}
}

@tableName("t8")
class WideR8 {
	public var id:Int = 0;
	public var r7Id:Int = 0;
	public var label:String = "";

	public function new() {}
}

/** `WideJoinTests.cs` — a query joins up to eight sources, and every arity offers the same thing. */
class WideJoinTests extends TestCase {
	/** Eight sources, joined one at a time. */
	static function eight():ISelectQuery8<WideR1, WideR2, WideR3, WideR4, WideR5, WideR6, WideR7, WideR8> {
		return Query.select(WideR1)
			.InnerJoin(Query.select(WideR2), (a, b) -> b.r1Id == a.id)
			.InnerJoin(Query.select(WideR3), (a, b, c) -> c.r2Id == b.id)
			.InnerJoin(Query.select(WideR4), (a, b, c, d) -> d.r3Id == c.id)
			.InnerJoin(Query.select(WideR5), (a, b, c, d, e) -> e.r4Id == d.id)
			.InnerJoin(Query.select(WideR6), (a, b, c, d, e, f) -> f.r5Id == e.id)
			.InnerJoin(Query.select(WideR7), (a, b, c, d, e, f, g) -> g.r6Id == f.id)
			.InnerJoin(Query.select(WideR8), (a, b, c, d, e, f, g, h) -> h.r7Id == g.id);
	}

	function testEightSourcesJoin() {
		final select = eight()
			.Where((a, b, c, d, e, f, g, h) -> h.label != null)
			.OrderByDesc((a, b, c, d, e, f, g, h) -> h.id)
			.Select((a, b, c, d, e, f, g, h) -> {name: a.name, label: h.label})
			.ToExpression();

		Assert.equals("t1", select.selectTableName());
		Assert.equals(7, select.Joins.length);
		for (i in 0...7) {
			Assert.equals(JoinType.Inner, select.join(i).Type);
			Assert.equals('t${i + 2}', select.joinedTableName(i));
		}

		final eighth = select.join(6).Source;

		// `!= null` is a question about null, so it stays a comparison against it.
		final notNull = select.whereBinary(NotEqual);
		notNull.Left.column("label");
		Assert.equals(eighth.Alias, select.sourceAlias(notNull.Left));
		notNull.Right.nullConst();

		Assert.isFalse(select.orderBy().Ascending);
		select.orderBy().Expression.column("id");
		Assert.equals(eighth.Alias, select.sourceAlias(select.orderBy().Expression));

		select.selectionOf("name").column("name");
		Assert.equals(select.Source.Alias, select.sourceAlias(select.selectionOf("name")));
		select.selectionOf("label").column("label");
		Assert.equals(eighth.Alias, select.sourceAlias(select.selectionOf("label")));
	}

	function testTheWidestArityIsAQueryLikeAnyOther() {
		final select = eight()
			.GroupBy((a, b, c, d, e, f, g, h) -> a.name)
			.SelectAggregation(g -> {name: g.key((a, b, c, d, e, f, g, h) -> a.name), rows: g.count()})
			.ToExpression();

		select.groupBy().column("name");
		Assert.equals(select.Source.Alias, select.sourceAlias(select.groupBy()));
		Assert.isNull(select.selectionOf("rows").aggregate(Count).Argument);
	}

	function testAWindowOverSevenSources() {
		final select = Query.select(WideR1)
			.InnerJoin(Query.select(WideR2), (a, b) -> b.r1Id == a.id)
			.InnerJoin(Query.select(WideR3), (a, b, c) -> c.r2Id == b.id)
			.InnerJoin(Query.select(WideR4), (a, b, c, d) -> d.r3Id == c.id)
			.Window(w -> w.PartitionBy((a, b, c, d) -> a.name).OrderBy((a, b, c, d) -> d.id))
			.SelectAggregation((x, w) -> {name: x.key((a, b, c, d) -> a.name), rank: x.count().over(w)})
			.ToExpression();

		final window = select.window("w");
		Assert.single(window.PartitionBy).column("name");
		Assert.equals(select.Source.Alias, select.sourceAlias(window.PartitionBy[0]));
		Assert.single(window.OrderBy).Expression.column("id");
		Assert.equals(select.join(2).Source.Alias, select.sourceAlias(window.OrderBy[0].Expression));

		// The aggregate names the window the statement defined rather than spelling out its own.
		final rank = select.selectionOf("rank").aggregate(Count);
		Assert.notNull(rank.Window);
		Assert.isTrue(window == rank.Window);
	}

	function testALateralAtTheWiderArities() {
		final select = Query.select(WideR1)
			.InnerJoin(Query.select(WideR2), (a, b) -> b.r1Id == a.id)
			.InnerJoin(Query.select(WideR3), (a, b, c) -> c.r2Id == b.id)
			.InnerJoin(Query.select(WideR4), (a, b, c, d) -> d.r3Id == c.id)
			.LeftJoinLateral((a, b, c, d) -> Query.select(WideR5)
				.Where(e -> e.r4Id == d.id)
				.Limit(1))
			.Select((a, b, c, d, e) -> {name: a.name, id: e.id})
			.ToExpression();

		final join = select.join(3);
		Assert.equals(JoinType.LeftLateral, join.Type);
		final lateral = join.Source.asQuery();

		// The lateral names the fourth source — a statement out from its own — which is what makes it
		// lateral rather than a plain join.
		final correlation = lateral.whereClause().binary(Equal);
		correlation.Left.column("r4Id");
		Assert.equals(0, correlation.Left.sourceIndex());
		Assert.equals(0, correlation.Left.sourceScope());
		correlation.Right.column("id");
		Assert.equals(3, correlation.Right.sourceIndex());
		Assert.equals(1, correlation.Right.sourceScope());
		Assert.equals(select.join(2).Source.Alias, select.AllSources()[correlation.Right.sourceIndex()].Alias);
	}
}
