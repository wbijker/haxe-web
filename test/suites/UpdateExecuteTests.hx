package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("staff")
class Staff {
	public var id:Int = 0;
	@columnNullable(false)
	public var name:String = "";
	public var nickname:Null<String>;
	public var level:Int = 0;

	public function new() {}
}

/**
	`UpdateExecuteTests.cs`: executable UPDATE statements from a configured table — simple
	SET/WHERE and the UPDATE … FROM (subquery) form. What each renders is checked; what each
	changes needs a database to change.
**/
class UpdateExecuteTests extends TestCase {
	static final NoDatabase = "needs a database: eval has none (PHP runtime only)";

	static final staff:DbTable<Staff> = Query.table(Staff);

	function testUpdate_SetWhere_Executes() {
		final update = staff.Update()
			.Set(s -> s.level, 2)
			.Where(s -> s.id == 1);

		Assert.equals("UPDATE staff AS t0 SET level = 2 WHERE t0.id = 1", new SqlTranslator().ToSql(update.ToExpression()));
		Assert.skip(NoDatabase);
	}

	function testUpdate_SetNull_RendersAndExecutes() {
		final update = staff.Update()
			.Set(s -> s.nickname, (null : Null<String>));

		Assert.equals("UPDATE staff AS t0 SET nickname = NULL", new SqlTranslator().ToSql(update.ToExpression()));
		Assert.skip(NoDatabase);
	}

	function testUpdateFromSource_JoinsSubqueryColumnsIntoSet() {
		// Copy Bob's level onto Ann via UPDATE … FROM (SELECT …).
		final source = staff.From().Where(s -> s.id == 2).Select(s -> {level: s.level});

		final update = staff.UpdateFrom(source)
			.Where((target, s) -> target.id == 1)
			.Set(target -> target.level, (target, s) -> s.level);

		Assert.equals("UPDATE staff AS t0 SET level = t1.level FROM (SELECT t2.level AS level FROM staff AS t2 WHERE t2.id = 2) AS t1 WHERE t0.id = 1",
			new SqlTranslator().ToSql(update.ToExpression()));
		Assert.skip(NoDatabase);
	}

	function testUpdate_CarriesItsTargetAssignmentAndFilter() {
		final expression = Assert.isType(staff.Update()
			.Set(s -> s.level, 3)
			.Where(s -> s.name == "Ann")
			.ToExpression(), UpdateExpression);

		Assert.equals("staff", expression.Target.tableName());
		Assert.equals(["level"], expression.assignedColumns());
		expression.assignedValue("level").value(3);
		expression.updateWhere().comparison("name", Equal, "Ann");
	}
}
