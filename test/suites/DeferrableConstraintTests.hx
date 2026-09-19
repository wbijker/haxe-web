package suites;

import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.TableConstraint;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DeferrableConstraintTests.cs`: DEFERRABLE constraints, rendered as PostgreSQL does. */
class DeferrableConstraintTests extends TestCase {
	static function Table():CreateTableExpression {
		final fk = ForeignKeyConstraint.Of("AuthorId", "authors", "Id");
		fk.Deferrable = true;
		fk.InitiallyDeferred = true;
		return new CreateTableExpression("books", [new ColumnDefinition("AuthorId", SqlInt)], [fk]);
	}

	function testPostgres_RendersDeferrable() {
		final sql = new SqlTranslator().ToSql(Table());
		Assert.contains("FOREIGN KEY (AuthorId) REFERENCES authors (Id) DEFERRABLE INITIALLY DEFERRED", sql);
	}

	function testSqlServer_IgnoresDeferrable() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}
}
