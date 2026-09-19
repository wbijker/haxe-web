package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `UpdateQueryTests.cs`. */
class UpdateQueryTests extends TestCase {
	/**
		The source a column names, resolved against the statement: a column written in a lambda
		names its source by the position of the parameter it was reached through.
	**/
	static function SourceOf(statement:UpdateExpression, column:ISqlExpression):ISqlSource {
		final parameter = Std.downcast(cast column.column().Source, ParameterSqlSource);
		return parameter == null ? column.column().Source : statement.AllSources()[parameter.Index];
	}

	function testUpdateSimple() {
		// UPDATE Book SET title = 'New Title' WHERE id = 1
		final exp = Assert.isType(Query.table(Book)
			.Update()
			.Where(b -> b.id == 1)
			.Set(b -> b.title, "New Title")
			.ToExpression(), UpdateExpression);

		Assert.equals("Book", exp.Target.tableName());

		Assert.equals(["title"], exp.assignedColumns());
		exp.assignedValue("title").value("New Title");

		exp.updateWhere().comparison("id", Equal, 1);
	}

	function testUpdateWithSubquery() {
		// UPDATE Book SET title = 'Updated'
		// FROM (SELECT * FROM Book WHERE authorId > 10) AS subquery
		// WHERE Book.id = subquery.id
		final query = Query.select(Book).Where(b -> b.authorId > 10);

		final exp = Assert.isType(Query.table(Book).UpdateFrom(query)
			.Where((a, b) -> a.id == b.id)
			.Set(t -> t.title, "Updated")
			.ToExpression(), UpdateExpression);

		Assert.equals("Book", exp.Target.tableName());

		// The rows to update are found through a subquery over the same table…
		final source = Assert.single(exp.FromSources).asQuery();
		Assert.equals("Book", source.selectTableName());
		source.whereClause().comparison("authorId", GreaterThan, 10);

		// …matched to the target by the condition that was written.
		final on = exp.updateWhere().columnComparison("id", Equal, "id");
		Assert.equals(exp.Target.Alias, SourceOf(exp, on.Left).Alias);
		Assert.equals(exp.FromSources[0].Alias, SourceOf(exp, on.Right).Alias);

		Assert.equals(["title"], exp.assignedColumns());
		exp.assignedValue("title").value("Updated");
	}
}
