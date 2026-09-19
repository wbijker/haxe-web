package codequery.queries;

import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.MergeAssignment;
import codequery.sqlexpressions.MergeWhenMatchedDelete;
import codequery.sqlexpressions.MergeWhenMatchedUpdate;
import codequery.sqlexpressions.MergeWhenNotMatchedInsert;
import codequery.sqlexpressions.MergeExpression;
import codequery.sqlexpressions.ProjectionKeys;
import codequery.sqlexpressions.ProjectionSqlExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;

/** What `IMergeInto` and `IMergeBuilder` are, underneath. */
class MergeBuilderImpl {
	final table:QualifiedTableName;
	var merge:Null<MergeExpression>;

	public function new(table:QualifiedTableName) {
		this.table = table;
	}

	/** What `Using` compiles down to: the source row set and the `ON` match condition. */
	public function UsingSource(source:SelectExpression, on:ISqlExpression):MergeBuilderImpl {
		final context = new SourceContext();
		final target = context.AddTableSource(table);
		final rows = context.AddQuerySource(source);
		merge = new MergeExpression(target, rows, on);
		return this;
	}

	/** What `WhenMatchedUpdate` compiles down to: each member of the projection is a column set. */
	public function MatchedUpdate(set:ISqlExpression, ?condition:ISqlExpression):MergeBuilderImpl {
		final assignments = [for (member in Members(set)) new MergeAssignment(member.Name, member.Expression)];
		Statement().Actions.push(new MergeWhenMatchedUpdate(assignments, condition));
		return this;
	}

	public function MatchedDelete(?condition:ISqlExpression):MergeBuilderImpl {
		Statement().Actions.push(new MergeWhenMatchedDelete(condition));
		return this;
	}

	/** What `WhenNotMatchedInsert` compiles down to: the projection's members are the columns and their values. */
	public function NotMatchedInsert(insert:ISqlExpression, ?condition:ISqlExpression):MergeBuilderImpl {
		final members = Members(insert);
		Statement().Actions.push(new MergeWhenNotMatchedInsert(
			members.map(m -> m.Name), members.map(m -> m.Expression), condition));
		return this;
	}

	/** The merge statement built so far. */
	public function Build():MergeExpression {
		return Statement();
	}

	function Statement():MergeExpression {
		if (merge == null) {
			throw "A merge needs a source before it can say what to do with one: call Using first";
		}
		return merge;
	}

	static function Members(projection:ISqlExpression):Array<codequery.sqlexpressions.ProjectionMember> {
		final structure = Std.downcast(cast projection, ProjectionSqlExpression);
		if (structure == null || structure.Members.filter(m -> m.Name == "").length > 0) {
			throw "A merge action names its columns, e.g. (t, s) -> {balance: s.balance}";
		}
		return structure.Members;
	}
}
