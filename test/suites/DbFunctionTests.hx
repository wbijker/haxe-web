package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/** `DbFunctionTests.Row`, less the array and JSON columns the port has no type for. */
class FunctionRow {
	public var id:Int = 0;
	public var amount:Float = 0;
	public var value:Float = 0;
	public var name:String = "";
	public var note:Null<String>;
	public var when:codequery.SqlDate;

	public function new() {}
}

/**
	`DbFunctionTests.cs`.

	Despite its name this file is about `DbFunctions` — the query-side function library — rendered by
	the PostgreSQL driver. The generic functions are the port's `Sql.*` calls and are ported against
	the translator; what is PostgreSQL's own (`PostgresFunctions`, arrays, JSON, `WITHIN GROUP`) is
	not. C#'s `Math.Abs(x)` is `Sql.abs(x)`, `a ?? b` is `Sql.coalesce(a, b)`, string `+` is
	`Sql.concat`, and `(int)x` is `Sql.castTo(x, SqlInt)`.
**/
class DbFunctionTests extends TestCase {
	static inline final Postgres = "PostgresFunctions: PostgreSQL-only functions not ported";

	final driver = new SqlTranslator();

	function testNumeric_Math_Functions() {
		Assert.contains("ABS(t0.amount)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.abs(r.amount)})));
		Assert.contains("SIGN(t0.amount)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.sign(r.amount)})));
		Assert.contains("CEIL(t0.amount)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.ceil(r.amount)})));
		Assert.contains("FLOOR(t0.amount)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.floor(r.amount)})));
		Assert.contains("ROUND(t0.amount, 2)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.round(r.amount, 2)})));
		Assert.contains("POWER(t0.value, 2)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.power(r.value, 2)})));
		Assert.contains("SQRT(t0.value)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.sqrt(r.value)})));
		Assert.contains("EXP(t0.value)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.exp(r.value)})));
		Assert.contains("LN(t0.value)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.ln(r.value)})));
		Assert.contains("LOG(t0.value)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.log(r.value)})));
	}

	function testConditional_And_Conversion() {
		Assert.contains("COALESCE(t0.note, 'x')", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.coalesce(r.note, "x")})));
		Assert.contains("NULLIF(t0.amount, 0)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.nullIf(r.amount, 0)})));
		Assert.contains("GREATEST(t0.amount, 0)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.greatest(r.amount, 0)})));
		Assert.contains("LEAST(t0.amount, 0)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.least(r.amount, 0)})));
		Assert.contains("CASE WHEN t0.amount > 0 THEN 'pos' ELSE 'neg' END",
			Pg(Query.select(FunctionRow).Select(r -> {v: r.amount > 0 ? "pos" : "neg"})));
	}

	/** `INITCAP`, `split_part` and `STRING_AGG` are PostgreSQL's own and are not ported. */
	function testString_Functions() {
		Assert.contains("t0.name || '!'", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.concat(r.name, "!")})));
		Assert.contains("LEFT(t0.name, 3)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.left(r.name, 3)})));
		Assert.contains("RIGHT(t0.name, 3)", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.right(r.name, 3)})));
		Assert.contains("t0.name LIKE 'A%'", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.like(r.name, "A%")})));
		Assert.contains("t0.name ILIKE 'a%'", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.ilike(r.name, "a%")})));
	}

	/** `date_trunc`, `to_char` and `gen_random_uuid` are PostgreSQL's own; `RANDOM()` is not. */
	function testDateTime_And_Value_Functions() {
		Assert.contains("RANDOM()", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.random()})));
	}

	function testCastAndNow_NowRenderOnPostgres() {
		Assert.contains("CAST(t0.amount AS INTEGER)",
			Pg(Query.select(FunctionRow).Select(r -> {v: (Sql.castTo(r.amount, SqlInt) : Int)})));
		Assert.contains("NOW()", Pg(Query.select(FunctionRow).Select(r -> {v: Sql.now()})));
	}

	/** The `FILTER (WHERE …)` aggregates are standard; the rest are PostgreSQL's own. */
	function testAdvanced_Aggregates() {
		final sql = Pg(Query.select(FunctionRow).SelectAggregation(a -> {
			positives: a.count().filter(r -> r.amount > 0),
			total: a.sum(r -> r.amount).filter(r -> r.amount > 0)
		}));

		Assert.contains("COUNT(*) FILTER (WHERE t0.amount > 0)", sql);
		Assert.contains("SUM(t0.amount) FILTER (WHERE t0.amount > 0)", sql);
	}

	function testArray_Functions() {
		Assert.skip(Postgres + " (arrays)");
	}

	function testJson_Build_And_Path_Functions() {
		Assert.skip(Postgres + " (JSON)");
	}

	function testDateConvert_Functions() {
		Assert.skip(Postgres);
	}

	function testSqlite_Executes_Functions() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function Pg(query:codequery.queries.ISelectQuery<Dynamic>):String {
		return driver.ToSql((cast query : codequery.queries.SelectQueryImpl).ToExpression());
	}
}
