package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `DeleteQueryTests.cs`. */
class DeleteQueryTests extends TestCase {
	/** The source a column names, resolved against the statement — see `UpdateQueryTests.SourceOf`. */
	static function SourceOf(statement:DeleteExpression, column:ISqlExpression):ISqlSource {
		final parameter = Std.downcast(cast column.column().Source, ParameterSqlSource);
		return parameter == null ? column.column().Source : statement.AllSources()[parameter.Index];
	}

	function testDeleteSimple() {
		// DELETE FROM Book WHERE id = 1
		final exp = Assert.isType(Query.table(Book)
			.Delete()
			.Where(b -> b.id == 1)
			.ToExpression(), DeleteExpression);

		Assert.equals("Book", exp.Target.tableName());
		exp.deleteWhere().comparison("id", Equal, 1);
	}

	function testDeleteWithSubquery() {
		// DELETE FROM Book
		// USING (SELECT * FROM Book WHERE authorId > 10) AS subquery
		// WHERE Book.id = subquery.id
		final exp = Assert.isType(Query.select(Book)
			.Where(b -> b.authorId > 10)
			.Delete(Book, (target, source) -> target.id == source.id)
			.ToExpression(), DeleteExpression);

		Assert.equals("Book", exp.Target.tableName());

		// The rows to delete come from a subquery over the same table…
		final source = Assert.single(exp.FromSources).asQuery();
		Assert.equals("Book", source.selectTableName());
		source.whereClause().comparison("authorId", GreaterThan, 10);

		// …matched to the target by the condition that was written.
		final on = exp.deleteWhere().columnComparison("id", Equal, "id");
		Assert.equals(exp.Target.Alias, SourceOf(exp, on.Left).Alias);
		Assert.equals(exp.FromSources[0].Alias, SourceOf(exp, on.Right).Alias);
	}
}
