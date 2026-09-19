# Porting the C# tests

The C# suite is `~/projects/CodeQuery/CodeQuery.Tests` (xunit, 293 files, ~2,300 tests). Every
test passes there. This folder is its Haxe port, one suite per C# file, same name.

## The harness

- `codequery.testing.TestCase` — extend it; every method named `testSomething` is a test.
- `codequery.testing.Assert` — `equals`, `isTrue`, `notNull`, `contains`, `doesNotContain`,
  `isType`, `throws`, `throwsMessage`, `count`, `single`, `empty`, `skip`.
- `codequery.testing.SqlAssert` — the C# `SqlAssert` and `*Access` helpers. Reach them with
  `using codequery.testing.SqlAssert;` so `select.whereBinary(And)`, `e.column("id")`,
  `select.joinOfType(Inner)`, `select.projection(2)`, `update.assignedValue("x")` read as the C#.
- `codequery.Query` — `Query.select(Book)` is C#'s `new SelectQuery<Book>()`;
  `Query.table(Author, "authors")` is `new Query<Author>("authors")`.
- `entities.Book`, `Author`, `AuthorGroup` — the shared test entities (`TestEntities.cs`).
  Other entities a C# file declares go in the suite file itself, or in `test/entities/`.
- Suites in `test/suites/` are found automatically. Do not edit `Suites.hx`.
- Run: `haxe test.hxml`. One suite: `TEST=SelectQuery haxe test.hxml`. Every test:
  `TEST_VERBOSE=1`.

Look at `test/suites/SelectQueryTests.hx` for the shape.

## Rules

1. **Port every test in every assigned file.** A test that cannot pass here is not dropped, it is
   `Assert.skip("<reason>")` — see below. The count of ported tests must equal the C# count.
2. **Names match the C#.** `LimitAndOffset_AreClausesOfTheStatement` becomes
   `testLimitAndOffset_AreClausesOfTheStatement`. `[Theory]` rows become one test each, suffixed.
3. **Fix the library, not the test.** If a test fails because the port is wrong or incomplete,
   fix `src/codequery` — the C# source in `~/projects/CodeQuery/CodeQuery` is the reference and it
   is always right. Prefer a new file to editing a shared one. The hot spots everyone touches are
   `ExpressionConverter.SqlCall` (the `Sql.*` switch), `SqlTranslator`, `SelectQueryExtensions`,
   `SqlExpressionWalker`/`ISqlExpressionVisitor`: keep edits there small and additive, and never
   reformat or reorder what is already there.
4. **Skip only what is out of scope, and say exactly what.** The reason string starts with the
   C# feature it needs, so reasons aggregate: `"MssqlSqlDriver: no SQL Server dialect"`,
   `"PgTrgm: PostgreSQL extension"`, `"EntityFramework: not ported"`, `"needs a database: eval
   has none (PHP runtime only)"`, `"DbFunction/DbStoredProc: routines not ported"`,
   `"JsonExpression: JSON not ported"`, `"Profiler/Logger/Interceptor: not ported"`,
   `"Transaction: not ported"`. Out of scope for the port: other dialects' rendering (Mssql,
   MySql, Postgres-specific spellings — the port renders one generic/PostgreSQL-ish dialect),
   PostgreSQL extensions, EF, JSON, routines/triggers, profiler/logger/interceptor,
   transactions/async, binary copy, anything that executes against a database.
   A test that is *partly* out of scope is ported for the part that is not.
5. **Before you finish:** `haxe test.hxml` must be green — 0 failed, 0 errored — across *all*
   suites, not only yours; and `haxe build.hxml` must still succeed. Then commit.
6. Do not touch `src/Main.hx`, `src/RunPhp.hx`, `src/RunMigrations.hx`.

## Reading the C#

Assertions map: `Assert.Equal(a, b)` → `Assert.equals(a, b)`; `Assert.IsType<T>(x)` →
`Assert.isType(x, T)`; `Assert.Throws<T>(() => …)` → `Assert.throws(() -> …)`;
`Assert.Contains(s, sql)` → `Assert.contains(s, sql)`. `new PostgresSqlDriver().ToSql(e)` /
`new SqliteSqlDriver().ToSql(e)` → `new SqlTranslator().ToSql(e)` where the expected SQL is
dialect-neutral; where the expected text is a dialect's own spelling, skip with the dialect
named. Entity fields are camelCase in Haxe (`b.Id` → `b.id`), and column names follow the field
unless `@columnName` says otherwise — so an expected `"Id"` in C# is `"id"` here.
