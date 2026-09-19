package suites;

import codequery.migrations.*;
import codequery.migrations.IMigrationPrompt;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.TableConstraint;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("company")
class Company {
	public var id:Int = 0;
	@:foreignKey(Employee) public var primaryContactId:Null<Int>;

	public function new() {}
}

@tableName("employee")
class Employee {
	public var id:Int = 0;
	@:foreignKey(Company) public var employerId:Null<Int>;

	public function new() {}
}

/**
	`MutualForeignKeyTests.cs`: two tables that point at each other. Neither can be created first,
	so the keys are added once both tables are there.
**/
class MutualForeignKeyTests extends TestCase {
	static function Both():SchemaSnapshot {
		final snapshot = new SchemaSnapshot();
		snapshot.Tables.push(SchemaInspector.FromType(Company));
		snapshot.Tables.push(SchemaInspector.FromType(Employee));
		return snapshot;
	}

	static function Plan(lift:Bool):Array<SchemaChangeExpression> {
		return MigrationPlanner.Plan(SchemaDiff.Create(new SchemaSnapshot(), Both()), new NonInteractiveMigrationPrompt(), lift);
	}

	static function Creates(ops:Array<SchemaChangeExpression>):Array<CreateTableExpression> {
		return [for (o in ops) if (Std.isOfType(o, CreateTableExpression)) (cast o : CreateTableExpression)];
	}

	static function ForeignKeys(create:CreateTableExpression):Array<ForeignKeyConstraint> {
		return [for (c in create.Constraints) if (Std.isOfType(c, ForeignKeyConstraint)) (cast c : ForeignKeyConstraint)];
	}

	static function IsAddedKey(o:SchemaChangeExpression):Bool {
		final add = Std.downcast(o, AddConstraintExpression);
		return add != null && Std.isOfType(add.Constraint, ForeignKeyConstraint);
	}

	function testLifted_NoCreateTableCarriesAForeignKey() {
		final creates = Creates(Plan(true));
		Assert.equals(2, creates.length);
		for (c in creates) {
			Assert.empty(ForeignKeys(c));
		}
	}

	function testLifted_TheKeysComeAfterEveryTable() {
		final ops = Plan(true);
		var lastCreate = -1;
		var firstKey = -1;
		var keys = 0;
		for (index in 0...ops.length) {
			if (Std.isOfType(ops[index], CreateTableExpression)) {
				lastCreate = index;
			}
			if (IsAddedKey(ops[index])) {
				keys++;
				if (firstKey < 0) {
					firstKey = index;
				}
			}
		}
		Assert.equals(2, keys);
		Assert.isTrue(firstKey > lastCreate, "a key was added before the last table existed");
	}

	function testLifted_TheColumnSaysWhatItPointsAt() {
		final create = Assert.single([for (c in Creates(Plan(true))) if (c.TableName == "company") c]);
		final sql = new SqlTranslator().ToDdlSql(create, true);

		// After the comma, or the comment would take the rest of the line with it.
		Assert.contains("-- → employee (id)", sql);
		Assert.contains("primaryContactId INTEGER,   -- → employee (id)", sql);
	}

	function testNotLifted_TheKeysStayInTheTable() {
		for (c in Creates(Plan(false))) {
			Assert.single(ForeignKeys(c));
		}
		Assert.empty([for (o in Plan(false)) if (Std.isOfType(o, AddConstraintExpression)) o]);
	}

	function testOnOneLine_ThereIsNoComment_BecauseThereIsNoRestOfTheLine() {
		final create = Assert.single([for (c in Creates(Plan(true))) if (c.TableName == "company") c]);
		Assert.doesNotContain("--", new SqlTranslator().ToSql(create));
	}

	function testSqliteDoesNotLift_AndSaysSoIfAskedToAddOne() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port (SupportsAddForeignKeyConstraint)");
	}
}
