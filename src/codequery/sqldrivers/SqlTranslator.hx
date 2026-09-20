package codequery.sqldrivers;

import codequery.sqlexpressions.AggregateSqlExpression;
import codequery.sqlexpressions.AllColumnsSqlExpression;
import codequery.sqlexpressions.BetweenSqlExpression;
import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.CaseSqlExpression;
import codequery.sqlexpressions.InSqlExpression;
import codequery.sqlexpressions.IsDistinctFromSqlExpression;
import codequery.sqlexpressions.NotSqlExpression;
import codequery.sqlexpressions.SqlFunctionExpression;
import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpressionVisitor;
import codequery.sqlexpressions.CteSqlSource;
import codequery.sqlexpressions.QuantifiedComparisonSqlExpression;
import codequery.sqlexpressions.RowLockMode;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.ScalarSubquerySqlExpression;
import codequery.sqlexpressions.SqlCastExpression;
import codequery.sqlexpressions.SqlCommentExpression;
import codequery.sqlexpressions.SqlExpressionWalker;
import codequery.sqlexpressions.SqlParameterExpression;
import codequery.sqlexpressions.SqlType;
import codequery.sqlexpressions.WindowDefinition;
import codequery.sqlexpressions.WindowFrame;
import codequery.sqlexpressions.WindowFunctionExpression;
import codequery.sqlexpressions.DeleteExpression;
import codequery.sqlexpressions.DistinctSqlExpression;
import codequery.sqlexpressions.ISqlStatement;
import codequery.sqlexpressions.InsertExpression;
import codequery.sqlexpressions.MergeExpression;
import codequery.sqlexpressions.MergeAction;
import codequery.sqlexpressions.MergeWhenMatchedDelete;
import codequery.sqlexpressions.MergeWhenMatchedUpdate;
import codequery.sqlexpressions.MergeWhenNotMatchedInsert;
import codequery.sqlexpressions.ObjectConstSqlExpression;
import codequery.sqlexpressions.UpdateExpression;
import codequery.sqlexpressions.ExistsSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.ISqlSource;
import codequery.sqlexpressions.JoinSqlExpression;
import codequery.sqlexpressions.JoinType;
import codequery.sqlexpressions.NamedWindowSqlSource;
import codequery.sqlexpressions.OrderByExpression;
import codequery.sqlexpressions.ParameterSqlSource;
import codequery.sqlexpressions.ProjectionSqlExpression;
import codequery.sqlexpressions.QuerySqlSource;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SqlBinaryOperator;
import codequery.sqlexpressions.StringOperationExpression;
import codequery.sqlexpressions.DateOperationSqlExpression;
import codequery.sqlexpressions.DateFormatSqlExpression;
import codequery.sqlexpressions.IntervalSqlExpression;
import codequery.sqlexpressions.SqlConstValue;
import codequery.sqlexpressions.TableSqlSource;
import codequery.sqlexpressions.StringOperationExpression;
import codequery.sqlexpressions.RowSqlExpression;
import codequery.sqlexpressions.Expr;
import codequery.queries.Subquery;

/**
	Renders a statement as SQL — the dialect, and nothing about where the SQL goes.

	A driver is this plus somewhere to send the result. Splitting them is what lets a statement be
	rendered with no connection anywhere near it, which is most of what this port does, and it is
	how the C# original is arranged too.

	A dialect that differs changes this: `Placeholder` is the first such difference — a value sent
	beside a statement is `$1` to PostgreSQL and `?` to anything speaking through PDO.
**/
class SqlTranslator implements ISqlTranslator implements ISqlExpressionVisitor<String> {
	/**
		The statement being rendered, in the order a lambda's parameters bind to its sources. A
		generated column names its source by position, so rendering one is a lookup here.
	**/
	var sources:Array<ISqlSource> = [];

	/** The values of the statement being rendered, in the order their placeholders were numbered. */
	var parameters:Array<SqlConstValue> = [];

	/** The statements being rendered, innermost last, so a column can name one further out. */
	var scopes:Array<Array<ISqlSource>> = [];

	/**
		The alias each source renders under, settled here rather than where it was built.

		A statement is built knowing nothing of what it will end up inside: a query built on its own
		numbers its sources from t0, and so does the query it is later made a subquery of. Naming
		them as they are rendered is what keeps the two apart.
	**/
	var aliases:haxe.ds.ObjectMap<ISqlSource, String> = new haxe.ds.ObjectMap();

	var aliasCounter:Int = 0;

	/**
		The statements marked as CTEs that the one being rendered reaches, under the names the WITH
		clause gives them — so a source that is one of them renders as its name.
	**/
	var cteNames:haxe.ds.ObjectMap<SelectExpression, String> = new haxe.ds.ObjectMap();

	/** What was sent beside the last statement rendered. */
	public var Parameters(default, null):Array<SqlConstValue> = [];

	/**
		Whether a value bound to the statement is written into it instead — escaped, as a literal
		is. What a view body, a migration file or a log line needs: nothing there can bind one.
	**/
	public var InlineValues:Bool = false;

	public function new() {}

	/**
		Renders whichever statement it is given. C# tells them apart by overloading; Haxe has no
		overloading, so the statement says which kind it is and this asks.
	**/
	public function ToSql(statement:ISqlStatement):String {
		// Each statement collects its own values; a placeholder is numbered by where it lands.
		parameters = [];
		aliases = new haxe.ds.ObjectMap();
		aliasCounter = 0;
		cteNames = new haxe.ds.ObjectMap();
		final sql = Render(statement);
		Parameters = parameters;
		return sql;
	}

	function Render(statement:ISqlStatement):String {
		final select = Std.downcast(cast statement, SelectExpression);
		if (select != null) {
			return ToSelectSql(select);
		}

		final update = Std.downcast(cast statement, UpdateExpression);
		if (update != null) {
			return Against(update.AllSources(), () -> UpdateSql(update));
		}

		final delete = Std.downcast(cast statement, DeleteExpression);
		if (delete != null) {
			return Against(delete.AllSources(), () -> DeleteSql(delete));
		}

		final insert = Std.downcast(cast statement, InsertExpression);
		if (insert != null) {
			return Against(insert.AllSources(), () -> InsertSql(insert));
		}

		final merge = Std.downcast(cast statement, MergeExpression);
		if (merge != null) {
			return Against(merge.AllSources(), () -> MergeSql(merge));
		}

		final ddl = Std.downcast(cast statement, codequery.sqlexpressions.SchemaChangeExpression);
		if (ddl != null) {
			return ToDdlSql(ddl);
		}

		final create = Std.downcast(cast statement, codequery.sqlexpressions.TableCreateExpression);
		if (create != null) {
			return new DdlTranslator(this).TableCreate(create);
		}

		// A migration's SQL is written rather than built, and goes through as it stands.
		final raw = Std.downcast(cast statement, codequery.migrations.RawStatement);
		if (raw != null) {
			return raw.Sql;
		}

		throw 'Cannot render ${Type.getClassName(Type.getClass(statement))}';
	}

	/**
		Each statement renders against its own sources, with the statements enclosing it kept
		beneath — which is what lets a lateral's inner query name the row it is joined to.
	**/
	function Against(statementSources:Array<ISqlSource>, render:Void->String):String {
		final outer = sources;
		for (source in statementSources) {
			Named(source);
		}
		scopes.push(statementSources);
		sources = statementSources;
		final sql = render();
		scopes.pop();
		sources = outer;
		return sql;
	}

	/** The alias a source renders under, given one the first time it is seen. */
	function Named(source:ISqlSource):String {
		// A window is referred to by the name it was given, not by an alias.
		if (Std.downcast(cast source, NamedWindowSqlSource) != null) {
			return source.Alias;
		}
		final known = aliases.get(source);
		if (known != null) {
			return known;
		}
		final given = "t" + aliasCounter++;
		aliases.set(source, given);
		return given;
	}

	function UpdateSql(update:UpdateExpression):String {
		if (update.Assignments.length == 0) {
			throw "An update sets something";
		}

		// The columns being assigned are the target's own, so they are named without its alias.
		final assignments = update.Assignments
			.map(a -> '${a.Column.ColumnName} = ${RenderExpression(a.Value)}')
			.join(", ");

		var sql = 'UPDATE ${Source(update.Target)} SET $assignments';
		if (update.FromSources.length > 0) {
			sql += ' FROM ${update.FromSources.map(Source).join(", ")}';
		}
		if (update.Where != null) {
			sql += ' WHERE ${RenderExpression(update.Where)}';
		}
		return sql + Returning(update.Returning);
	}

	function DeleteSql(delete:DeleteExpression):String {
		var sql = 'DELETE FROM ${Source(delete.Target)}';
		if (delete.FromSources.length > 0) {
			sql += ' USING ${delete.FromSources.map(Source).join(", ")}';
		}
		if (delete.Where != null) {
			sql += ' WHERE ${RenderExpression(delete.Where)}';
		}
		return sql + Returning(delete.Returning);
	}

	function InsertSql(insert:InsertExpression):String {
		final target = Std.downcast(cast insert.Target, TableSqlSource);
		if (target == null) {
			throw "Rows are inserted into a table";
		}

		final columns = insert.Columns.map(column -> column.ColumnName).join(", ");
		var sql = 'INSERT INTO ${target.Table} ($columns)';

		if (insert.FromSelect != null) {
			sql += ' ${Nested(insert.FromSelect)}';
		} else {
			final rows = insert.Values.map(row -> '(${row.map(v -> InsertValue(insert, v)).join(", ")})').join(", ");
			sql += ' VALUES $rows';
		}
		sql += Overriding(insert.Overriding);
		sql += Conflict(insert);
		return sql + Returning(insert.Returning);
	}

	/**
		One value of an insert, as its strategy says: sent beside the statement, where a value
		written into the row list is bound after all; or written in, where a bound one is inlined.
	**/
	function InsertValue(insert:InsertExpression, value:ISqlExpression):String {
		// Bound or written whole, a composite's fields with it.
		return switch insert.Strategy.ValueMode {
			case Parameterized: Bound(value);
			case Inline | BinaryCopy: Written(value);
		}
	}

	function Overriding(mode:codequery.sqlexpressions.IdentityOverride):String {
		return switch mode {
			case None: "";
			case SystemValue: " OVERRIDING SYSTEM VALUE";
			case UserValue: " OVERRIDING USER VALUE";
		}
	}

	function Conflict(insert:InsertExpression):String {
		if (insert.OnConflict == null) {
			return "";
		}
		final on = insert.ConflictColumns.length == 0 ? "" : ' (${insert.ConflictColumns.join(", ")})';
		return switch insert.OnConflict {
			case DoNothing:
				' ON CONFLICT$on DO NOTHING';
			case DoUpdate:
				// Written-out assignments where the caller gave them; otherwise the columns take the
				// values that were offered, which is what an upsert means when nobody says otherwise.
				final set = insert.ConflictUpdates.length > 0
					? insert.ConflictUpdates
						.map(a -> '${a.Column.ColumnName} = ${RenderExpression(a.Value)}')
						.join(", ")
					: ConflictUpdateColumns(insert).map(c -> '$c = EXCLUDED.$c').join(", ");
				' ON CONFLICT$on DO UPDATE SET $set';
		}
	}

	function Returning(returning:Array<ISqlExpression>):String {
		return returning.length == 0 ? "" : ' RETURNING ${returning.map(RenderExpression).join(", ")}';
	}

	/** The columns a DO UPDATE sets: the explicit list, else every inserted column that is not a conflict column. */
	function ConflictUpdateColumns(insert:InsertExpression):Array<String> {
		return insert.ConflictUpdateColumns.length > 0
			? insert.ConflictUpdateColumns
			: insert.Columns.map(c -> c.ColumnName).filter(c -> insert.ConflictColumns.indexOf(c) < 0);
	}

	/** Bound as a parameter, whatever it arrived as. NULL stays written: there is no value to bind. */
	function Bound(value:ISqlExpression):String {
		final composite = Std.downcast(cast value, ObjectConstSqlExpression);
		if (composite != null) {
			return ObjectRow(composite, composite.Fields.map(Bound));
		}
		final constant = Std.downcast(cast value, ConstSqlExpression);
		if (constant != null && !constant.Value.match(SqlConstNull)) {
			return OnParameter(new SqlParameterExpression(constant.Value));
		}
		return RenderExpression(value);
	}

	/** Written into the statement, whatever it arrived as — not even a value that came as a parameter is bound. */
	function Written(value:ISqlExpression):String {
		final composite = Std.downcast(cast value, ObjectConstSqlExpression);
		if (composite != null) {
			return ObjectRow(composite, composite.Fields.map(Written));
		}
		final parameter = Std.downcast(cast value, SqlParameterExpression);
		if (parameter != null) {
			return RenderConst(parameter.Value);
		}
		return RenderExpression(value);
	}

	/** A composite around its fields, already rendered: `ROW(f1, f2)::TypeName`. */
	function ObjectRow(composite:ObjectConstSqlExpression, fields:Array<String>):String {
		return 'ROW(${fields.join(", ")})::${composite.TypeName}';
	}

	function MergeSql(merge:MergeExpression):String {
		var sql = 'MERGE INTO ${Source(merge.Target)} USING ${Source(merge.Source)} ON ${RenderExpression(merge.On)}';
		for (action in merge.Actions) {
			sql += " " + MergeActionSql(action);
		}
		return sql;
	}

	function MergeActionSql(action:MergeAction):String {
		final and = action.Condition == null ? "" : ' AND ${RenderExpression(action.Condition)}';

		final update = Std.downcast(action, MergeWhenMatchedUpdate);
		if (update != null) {
			final sets = update.Assignments.map(a -> '${a.Column} = ${RenderExpression(a.Value)}').join(", ");
			return 'WHEN MATCHED$and THEN UPDATE SET $sets';
		}

		final delete = Std.downcast(action, MergeWhenMatchedDelete);
		if (delete != null) {
			return 'WHEN MATCHED$and THEN DELETE';
		}

		final insert = Std.downcast(action, MergeWhenNotMatchedInsert);
		if (insert != null) {
			final values = insert.Values.map(RenderExpression).join(", ");
			return 'WHEN NOT MATCHED$and THEN INSERT (${insert.Columns.join(", ")}) VALUES ($values)';
		}

		throw 'Merge action ${Type.getClassName(Type.getClass(action))} is not supported';
	}

	/** `TRUNCATE TABLE <table>`. */
	public function BuildTruncateSql(tableName:String, ?schema:String):String {
		return 'TRUNCATE TABLE ${schema == null ? tableName : '$schema.$tableName'}';
	}

	/**
		Moves the table's key generator past `highestKey`, so the next generated key does not
		collide with one already loaded. The sequence is found from the column, which is what
		`pg_get_serial_sequence` is for.
	**/
	public function BuildResyncIdentitySql(tableName:String, ?schema:String, columnName:String, highestKey:Int):String {
		final qualified = schema == null ? tableName : '$schema.$tableName';
		return 'SELECT setval(pg_get_serial_sequence(\'$qualified\', \'$columnName\'), $highestKey)';
	}

	/**
		The whole statement: the CTEs it reaches hoisted into a WITH clause in front of it, in
		dependency order, and its comments around it.
	**/
	function ToSelectSql(expression:SelectExpression):String {
		final ctes = CollectCtes(expression);
		var made = 1;
		for (cte in ctes) {
			cteNames.set(cte, cte.CteName != null ? cte.CteName : "cte" + made++);
		}

		// The definitions first, so their sources take the first aliases, as they read.
		final named = ctes.map(cte -> '${cteNames.get(cte)} AS (${Against(cte.AllSources(), () -> Statement(cte))})');
		var sql = Against(expression.AllSources(), () -> Statement(expression));
		if (ctes.length > 0) {
			final recursive = ctes.filter(cte -> cte.IsRecursive).length > 0 ? "RECURSIVE " : "";
			sql = 'WITH $recursive${named.join(", ")} $sql';
		}

		// A line comment runs to the end of its line, so one of several lines is several comments.
		final lines = [];
		if (expression.CommentAbove != null) {
			for (line in CommentLines(expression.CommentAbove)) {
				lines.push(line);
			}
		}
		lines.push(sql);
		if (expression.CommentBelow != null) {
			for (line in CommentLines(expression.CommentBelow)) {
				lines.push(line);
			}
		}
		return lines.join("\n");
	}

	static function CommentLines(text:String):Array<String> {
		return StringTools.replace(text, "\r\n", "\n").split("\n").map(line -> "-- " + StringTools.rtrim(line));
	}

	/**
		The CTE-marked statements the root reaches through its sources, its joins' and its unions',
		a statement's dependencies before the statement itself. The root is not one of them even
		when marked: it is the statement being rendered.
	**/
	static function CollectCtes(root:SelectExpression):Array<SelectExpression> {
		final ordered = [];
		final seen = new haxe.ds.ObjectMap<SelectExpression, Bool>();
		final onStack = new haxe.ds.ObjectMap<SelectExpression, Bool>();

		function visit(expression:SelectExpression, isRoot:Bool):Void {
			if (onStack.exists(expression)) {
				return;
			}
			onStack.set(expression, true);
			for (source in CteSources(expression)) {
				final query = Std.downcast(cast source, QuerySqlSource);
				if (query != null) {
					visit(query.Query, false);
				}
			}
			if (!isRoot && expression.IsCte && !seen.exists(expression)) {
				seen.set(expression, true);
				ordered.push(expression);
			}
		}

		visit(root, true);
		return ordered;
	}

	static function CteSources(expression:SelectExpression):Array<ISqlSource> {
		final sources:Array<ISqlSource> = [expression.Source];
		for (join in expression.Joins) {
			sources.push(join.Source);
		}
		for (union in expression.Unions) {
			for (source in CteSources(union.Query)) {
				sources.push(source);
			}
		}
		return sources;
	}


	/**
		A statement rendered against its own sources, wherever it stands — on its own, or inside
		another. A bare projection wrapper says nothing and is taken off first, so
		`SELECT * FROM (SELECT …) AS t` is `SELECT …`.
	**/
	function Nested(expression:SelectExpression):String {
		final statement = Subquery.Unwrapped(expression);
		return Against(statement.AllSources(), () -> Statement(statement));
	}

	/**
		The statement a projection wrapper wraps, rendered with the wrapper out of the way.

		The wrapper is not a statement anyone wrote a lambda over: a column the projected statement
		reads from further out counts statements from where its lambda was written, and the wrapper
		was put around it afterwards. So the wrapper's frame is lifted off while what it wraps is
		rendered, and put back after.
	**/
	function Projected(query:QuerySqlSource):String {
		final wrapper = scopes.pop();
		final sql = Nested(query.Query);
		scopes.push(wrapper);
		return sql;
	}

	/** The statement itself, rendered against whichever sources are in scope. */
	function Statement(expression:SelectExpression):String {
		// The named queries come first: what follows them can select from them.
		var sql = "";
		if (expression.With.length > 0) {
			final recursive = expression.With.filter(cte -> cte.Recursive).length > 0 ? "RECURSIVE " : "";
			final named = expression.With
				.map(cte -> '${cte.Name} AS (${Nested(cte.Query)})')
				.join(", ");
			sql += 'WITH $recursive$named ';
		}

		sql += 'SELECT${Distinct(expression)} ${Selection(expression)} FROM ${Source(expression.Source)}';
		for (join in expression.Joins) {
			sql += " " + Join(join);
		}
		if (expression.Where != null) {
			sql += ' WHERE ${RenderExpression(expression.Where)}';
		}
		if (expression.GroupingSets.length > 0) {
			final sets = expression.GroupingSets
				.map(set -> '(${set.map(RenderExpression).join(", ")})')
				.join(", ");
			sql += ' GROUP BY GROUPING SETS ($sets)';
		} else if (expression.GroupBy.length > 0) {
			final keys = expression.GroupBy.map(RenderExpression).join(", ");
			sql += switch expression.Grouping {
				case None | GroupingSets: ' GROUP BY $keys';
				case Rollup: ' GROUP BY ROLLUP ($keys)';
				case Cube: ' GROUP BY CUBE ($keys)';
			}
		}
		if (expression.Having != null) {
			sql += ' HAVING ${RenderExpression(expression.Having)}';
		}
		if (expression.Windows.length > 0) {
			sql += ' WINDOW ${expression.Windows.map(RenderWindowDefinition).join(", ")}';
		}
		if (expression.OrderBy.length > 0) {
			sql += ' ORDER BY ${expression.OrderBy.map(RenderOrderBy).join(", ")}';
		}
		sql += RowLimit(expression);
		sql += Locking(expression);

		// A set operation joins two whole statements, so it comes after everything either says.
		for (union in expression.Unions) {
			final keyword = switch union.Type {
				case Union: "UNION";
				case UnionAll: "UNION ALL";
				case Intersect: "INTERSECT";
				case IntersectAll: "INTERSECT ALL";
				case Except: "EXCEPT";
				case ExceptAll: "EXCEPT ALL";
			}
			sql += ' $keyword ${Nested(union.Query)}';
		}
		return sql;
	}

	function Selection(expression:SelectExpression):String {
		return expression.Selection == null ? "*" : RenderExpression(expression.Selection);
	}

	function Source(source:ISqlSource):String {
		final window = Std.downcast(cast source, NamedWindowSqlSource);
		if (window != null) {
			throw "A window is named by the aggregates reading it, not selected from";
		}

		final table = Std.downcast(cast source, TableSqlSource);
		if (table != null) {
			return '${table.Table} AS ${Named(table)}';
		}

		final cte = Std.downcast(cast source, CteSqlSource);
		if (cte != null) {
			return '${cte.Cte.Name} AS ${Named(cte)}';
		}

		final query = Std.downcast(cast source, QuerySqlSource);
		if (query != null) {
			// A CTE is read by the name the WITH clause gave it rather than inlined; so is a query
			// that is nothing but `SELECT * FROM <cte>`, which is what a CTE handed to a join is.
			final cteName = cteNames.get(query.Query);
			if (cteName != null) {
				return '$cteName AS ${Named(query)}';
			}
			final wrapped = Std.downcast(cast query.Query.Source, QuerySqlSource);
			if (query.Query.IsSimpleWrapper && wrapped != null && cteNames.get(wrapped.Query) != null) {
				return '${cteNames.get(wrapped.Query)} AS ${Named(query)}';
			}
			// A query that is nothing but a table is that table, and reads better joined as one.
			final inner = Std.downcast(cast query.Query.Source, TableSqlSource);
			if (query.Query.IsSimpleTableQuery && inner != null) {
				return '${inner.Table} AS ${Named(query)}';
			}
			return '(${Against(query.Query.AllSources(), () -> Statement(query.Query))}) AS ${Named(query)}';
		}

		final values = Std.downcast(cast source, codequery.sqlexpressions.ValueSqlSource);
		if (values != null) {
			final rows = values.Rows.map(row -> '(${row.map(RenderExpression).join(", ")})').join(", ");
			return '(VALUES $rows) AS ${Named(values)}(${values.ColumnNames.join(", ")})';
		}

		throw 'Cannot render a source of ${Type.getClassName(Type.getClass(source))}';
	}

	function Join(join:JoinSqlExpression):String {
		// A lateral over a plain table names nothing of the row it is joined to, so it is the
		// ordinary join it amounts to, and the word is dropped.
		final plain = PlainLateral(join);
		if (plain != null) {
			final table = '${plain.Table} AS ${Named(join.Source)}';
			return join.Type == LeftLateral ? 'LEFT JOIN $table ON TRUE' : 'CROSS JOIN $table';
		}

		final sql = '${JoinKeyword(join.Type)} ${Source(join.Source)}';
		if (join.On != null) {
			return '$sql ON ${RenderExpression(join.On)}';
		}
		// A left join needs a condition even where the correlation is inside the query, and TRUE is
		// the one that keeps every outer row.
		return join.Type == LeftLateral ? '$sql ON TRUE' : sql;
	}

	/** The table a lateral join is over, where its query is that table and nothing more. */
	function PlainLateral(join:JoinSqlExpression):Null<TableSqlSource> {
		if (join.Type != CrossLateral && join.Type != LeftLateral) {
			return null;
		}
		final query = Std.downcast(cast join.Source, QuerySqlSource);
		if (query == null) {
			return null;
		}
		final statement = Subquery.Unwrapped(query.Query);
		return Subquery.IsPlain(statement) ? Std.downcast(cast statement.Source, TableSqlSource) : null;
	}

	function JoinKeyword(type:JoinType):String {
		return switch type {
			case Inner: "INNER JOIN";
			case Left: "LEFT JOIN";
			case Right: "RIGHT JOIN";
			case Outer: "FULL OUTER JOIN";
			case Cross: "CROSS JOIN";
			case CrossLateral: "CROSS JOIN LATERAL";
			case LeftLateral: "LEFT JOIN LATERAL";
		}
	}

	function Locking(expression:SelectExpression):String {
		final mode = switch expression.Lock {
			case None: return "";
			case Update: "FOR UPDATE";
			case NoKeyUpdate: "FOR NO KEY UPDATE";
			case Share: "FOR SHARE";
			case KeyShare: "FOR KEY SHARE";
		}
		// Only one of the two: a row is either passed over or waited for.
		final waiting = expression.LockSkipLocked ? " SKIP LOCKED" : (expression.LockNoWait ? " NOWAIT" : "");
		final of = expression.LockTables.length == 0 ? "" : ' OF ${expression.LockTables.map(Named).join(", ")}';
		return ' $mode$of$waiting';
	}

	function Distinct(expression:SelectExpression):String {
		if (expression.DistinctOn.length > 0) {
			return ' DISTINCT ON (${expression.DistinctOn.map(RenderExpression).join(", ")})';
		}
		return expression.IsDistinct ? " DISTINCT" : "";
	}

	function RenderOrderBy(term:OrderByExpression):String {
		final sql = '${RenderExpression(term.Expression)} ${term.Ascending ? "ASC" : "DESC"}';
		return switch term.Nulls {
			case Default: sql;
			case First: '$sql NULLS FIRST';
			case Last: '$sql NULLS LAST';
		}
	}

	/**
		`LIMIT`/`OFFSET` says it in the fewest words, but neither can express ties or a percentage,
		so a query asking for either is rendered in the standard's longer form instead.
	**/
	function RowLimit(expression:SelectExpression):String {
		if (!expression.WithTies && !expression.Percent) {
			var sql = "";
			if (expression.Limit != null) {
				sql += ' LIMIT ${expression.Limit}';
			}
			if (expression.Offset != null) {
				sql += ' OFFSET ${expression.Offset}';
			}
			return sql;
		}

		var sql = "";
		if (expression.Offset != null) {
			sql += ' OFFSET ${expression.Offset} ROWS';
		}
		if (expression.Limit != null) {
			final percent = expression.Percent ? " PERCENT" : "";
			final ties = expression.WithTies ? "WITH TIES" : "ONLY";
			sql += ' FETCH NEXT ${expression.Limit}$percent ROWS $ties';
		}
		return sql;
	}

	/** Every expression goes through the visitor, so a kind nobody handles will not compile. */
	public function RenderExpression(e:ISqlExpression):String {
		return SqlExpressionWalker.Visit(e, this);
	}

	public function OnColumn(e:ColumnSqlExpression):String {
		return '${AliasOf(e.Source)}.${e.ColumnName}';
	}

	public function OnAllColumns(e:AllColumnsSqlExpression):String {
		return '${AliasOf(e.Source)}.*';
	}

	public function OnConst(e:ConstSqlExpression):String {
		return RenderConst(e.Value);
	}

	public function OnParameter(e:SqlParameterExpression):String {
		if (InlineValues) {
			return RenderConst(e.Value);
		}
		parameters.push(e.Value);
		e.Ordinal = parameters.length;
		return Placeholder(e.Ordinal);
	}

	/**
		How a value sent beside the statement is written into it.

		Numbered by default, which is what PostgreSQL reads. A dialect that counts them by position
		instead overrides this.
	**/
	public function Placeholder(ordinal:Int):String {
		return "$" + ordinal;
	}

	public function OnBinary(e:BinarySqlExpression):String {
		final nullTest = NullTest(e);
		return nullTest != null
			? nullTest
			: '${Operand(e, e.Left)} ${RenderOperator(e.Operator)} ${Operand(e, e.Right)}';
	}

	public function OnNot(e:NotSqlExpression):String {
		return 'NOT (${RenderExpression(e.Operand)})';
	}

	public function OnIn(e:InSqlExpression):String {
		final keyword = e.Negate ? "NOT IN" : "IN";
		// Not correlated: the subquery stands on its own sources, so the outer ones are out of
		// scope inside it — unlike EXISTS, whose whole point is to reach them.
		final of = e.Subquery != null
			? Nested(e.Subquery)
			: e.Values.map(RenderExpression).join(", ");
		return '${RenderExpression(e.Value)} $keyword ($of)';
	}

	public function OnBetween(e:BetweenSqlExpression):String {
		final keyword = e.Negate ? "NOT BETWEEN" : "BETWEEN";
		return '${RenderExpression(e.Value)} $keyword ${RenderExpression(e.Lower)} AND ${RenderExpression(e.Upper)}';
	}

	public function OnIsDistinctFrom(e:IsDistinctFromSqlExpression):String {
		final keyword = e.Negate ? "IS NOT DISTINCT FROM" : "IS DISTINCT FROM";
		return '${RenderExpression(e.Left)} $keyword ${RenderExpression(e.Right)}';
	}

	public function OnCase(e:CaseSqlExpression):String {
		var sql = e.Operand == null ? "CASE" : 'CASE ${RenderExpression(e.Operand)}';
		for (branch in e.Branches) {
			sql += ' WHEN ${RenderExpression(branch.When)} THEN ${RenderExpression(branch.Then)}';
		}
		if (e.Otherwise != null) {
			sql += ' ELSE ${RenderExpression(e.Otherwise)}';
		}
		return sql + " END";
	}

	public function OnFunction(e:SqlFunctionExpression):String {
		// A name core defined is spelled by the dialect; any other name is a plain call.
		final known = FunctionRendering.KnownFunction(e, this);
		if (known != null) {
			return known;
		}
		final arguments = e.Arguments.map(RenderExpression);
		if (e.WithinGroup != null) {
			// Ascending is the default and is left unsaid, as the C# leaves it.
			final ordered = e.WithinGroup.map(term -> term.Ascending ? RenderExpression(term.Expression) : RenderOrderBy(term));
			return '${e.Name}(${arguments.join(", ")}) WITHIN GROUP (ORDER BY ${ordered.join(", ")})';
		}
		return e.Infix ? arguments.join(' ${e.Name} ') : '${e.Name}(${arguments.join(", ")})';
	}

	public function OnCast(e:SqlCastExpression):String {
		return 'CAST(${RenderExpression(e.Value)} AS ${RenderType(e.Type)})';
	}

	public function OnRaw(e:RawSqlExpression):String {
		return e.Sql;
	}

	public function OnAggregate(e:AggregateSqlExpression):String {
		return RenderAggregate(e);
	}

	public function OnProjection(e:ProjectionSqlExpression):String {
		return e.Members.map(member -> {
			// A comment on a projected column follows the name: what it is called, then what it means.
			final commented = Std.downcast(cast member.Expression, SqlCommentExpression);
			if (commented != null && member.Name != "") {
				return '${RenderExpression(commented.Value)} AS ${member.Name} ${Comment(commented.Text)}';
			}
			final selected = RenderExpression(member.Expression);
			// A projection of one expression names nothing, so there is nothing to alias it as.
			return member.Name == "" ? selected : '$selected AS ${member.Name}';
		}).join(", ");
	}

	/** A value with its comment beside it, anywhere that is not a projected column. */
	public function OnComment(e:SqlCommentExpression):String {
		return '${RenderExpression(e.Value)} ${Comment(e.Text)}';
	}

	/** The block form, the only one that can sit inside a statement. */
	static function Comment(text:String):String {
		return '/* $text */';
	}

	public function OnExists(e:ExistsSqlExpression):String {
		return '${e.Negate ? "NOT EXISTS" : "EXISTS"} (${Correlated(e.Subquery)})';
	}

	public function OnScalarSubquery(e:ScalarSubquerySqlExpression):String {
		// A place that takes one value says so, rather than letting the database refuse the statement.
		if (Subquery.Unwrapped(e.Subquery).Selection == null) {
			throw "A scalar subquery takes one value from each row, and this one selects the whole row. "
				+ "Select the value wanted, or gather the rows with ToList().";
		}
		return '(${Correlated(e.Subquery)})';
	}

	public function OnQuantified(e:QuantifiedComparisonSqlExpression):String {
		final quantifier = switch e.Quantifier {
			case Any: "ANY";
			case All: "ALL";
		}
		return '${RenderExpression(e.Value)} ${RenderOperator(e.Operator)} $quantifier (${Nested(e.Subquery)})';
	}

	public function OnRow(e:RowSqlExpression):String {
		return '(${e.Values.map(RenderExpression).join(", ")})';
	}

	public function OnWindowFunction(e:WindowFunctionExpression):String {
		final name = switch e.Function {
			case RowNumber: "ROW_NUMBER";
			case Rank: "RANK";
			case DenseRank: "DENSE_RANK";
			case Lead: "LEAD";
			case Lag: "LAG";
			case FirstValue: "FIRST_VALUE";
			case LastValue: "LAST_VALUE";
			case Ntile: "NTILE";
			case NthValue: "NTH_VALUE";
			case PercentRank: "PERCENT_RANK";
			case CumeDist: "CUME_DIST";
		}
		// A window function only means anything over a window, so it always has one.
		final over = e.Window != null ? e.Window.Name : RenderOver(e.Over);
		return '$name(${e.Arguments.map(RenderExpression).join(", ")}) OVER $over';
	}

	public function OnObjectConst(e:ObjectConstSqlExpression):String {
		return ObjectRow(e, e.Fields.map(RenderExpression));
	}

	public function OnOrderBy(e:OrderByExpression):String {
		return RenderOrderBy(e);
	}

	public function OnDistinct(e:DistinctSqlExpression):String {
		return 'DISTINCT ${RenderExpression(e.Value)}';
	}

	/** A window written out where it is used, rather than named on the statement. */
	function RenderOver(over:WindowDefinition):String {
		final parts = [];
		if (over.PartitionBy.length > 0) {
			parts.push('PARTITION BY ${over.PartitionBy.map(RenderExpression).join(", ")}');
		}
		if (over.OrderBy.length > 0) {
			parts.push('ORDER BY ${over.OrderBy.map(RenderOrderBy).join(", ")}');
		}
		if (over.Frame != null) {
			parts.push(RenderFrame(over.Frame));
		}
		return '(${parts.join(" ")})';
	}

	function RenderFrame(frame:WindowFrame):String {
		final kind = switch frame.Kind {
			case Rows: "ROWS";
			case Range: "RANGE";
		}
		return '$kind BETWEEN ${RenderBound(frame.Start)} AND ${RenderBound(frame.End)}';
	}

	function RenderBound(bound:codequery.sqlexpressions.WindowBound):String {
		return switch bound {
			case UnboundedPreceding: "UNBOUNDED PRECEDING";
			case Preceding(rows): '$rows PRECEDING';
			case CurrentRow: "CURRENT ROW";
			case Following(rows): '$rows FOLLOWING';
			case UnboundedFollowing: "UNBOUNDED FOLLOWING";
		}
	}

	/**
		One schema change as the DDL that makes it.

		A dialect that spells a type or an ALTER differently overrides this or `RenderType`; nothing
		about a change itself is dialect-specific, which is why the change is data and this is not.
	**/
	public function ToDdl(change:codequery.migrations.SchemaChange):String {
		return switch change {
			case CreateView(view) | AlterView(_, view):
				BuildCreateViewSql(view.Name, view.Select, view.Materialized, view.Strategy);
			case DropView(view):
				BuildDropViewSql(view.Name, view.Materialized);
			case _:
				ToDdlSql(DdlTranslator.Expression(change));
		}
	}

	/** `CREATE [MATERIALIZED] VIEW`, as the strategy says to make it. */
	public function BuildCreateViewSql(name:String, select:String, materialized:Bool = false,
			?strategy:codequery.migrations.DbMigrationStrategy):String {
		return ViewStatements.Create(name, select, materialized, strategy == null ? CreateOrReplace : strategy);
	}

	/** `DROP [MATERIALIZED] VIEW`. */
	public function BuildDropViewSql(name:String, materialized:Bool = false):String {
		return ViewStatements.Drop(name, materialized);
	}

	/** A schema change expression as DDL — `pretty` lays a CREATE TABLE out one column a line. */
	public function ToDdlSql(change:codequery.sqlexpressions.SchemaChangeExpression, pretty:Bool = false):String {
		return new DdlTranslator(this, pretty).Render(change);
	}

	public function RenderType(type:SqlType):String {
		return switch type {
			case SqlInt: "INTEGER";
			case SqlBigInt: "BIGINT";
			case SqlFloat: "DOUBLE PRECISION";
			case SqlDecimal(precision, scale): 'DECIMAL($precision, $scale)';
			case SqlBool: "BOOLEAN";
			case SqlText: "TEXT";
			case SqlVarChar(length): 'VARCHAR($length)';
			case SqlDate: "DATE";
			case SqlTimestamp: "TIMESTAMP";
			case SqlUnknown: throw "A cast needs a type to cast to";
			case SqlSmallInt: "SMALLINT";
			case SqlReal: "REAL";
			case SqlNamed(name): name;
			case SqlChar(length): 'CHAR($length)';
			case SqlGuid: "UUID";
			case SqlJson: "JSON";
			case SqlBinary: "BYTEA";
			case SqlTime: "TIME";
		}
	}

	/**
		A subquery that may name the outer statement's rows. It renders against its own sources like
		any other: a column it reads from outside says how many statements out it is, and the
		statements enclosing this one are kept beneath it for that.
	**/
	function Correlated(subquery:SelectExpression):String {
		return Nested(subquery);
	}

	function RenderAggregate(aggregate:AggregateSqlExpression):String {
		if (Std.isOfType(aggregate, codequery.sqlexpressions.UnfinishedAggregateSqlExpression)) {
			throw codequery.sqlexpressions.UnfinishedAggregateSqlExpression.Message;
		}
		final name = switch aggregate.Type {
			case Count: "COUNT";
			case Sum: "SUM";
			case Avg: "AVG";
			case Min: "MIN";
			case Max: "MAX";
		}
		if (aggregate.Distinct && aggregate.Argument == null) {
			throw "DISTINCT needs something to be distinct about, and this aggregate counts rows";
		}
		final distinct = aggregate.Distinct ? "DISTINCT " : "";
		// COUNT with nothing to count counts rows.
		final argument = aggregate.Argument == null ? "*" : RenderExpression(aggregate.Argument);
		var sql = '$name($distinct$argument)';

		if (aggregate.Filter != null) {
			sql += ' FILTER (WHERE ${RenderExpression(aggregate.Filter)})';
		}
		if (aggregate.Window != null) {
			sql += ' OVER ${aggregate.Window.Name}';
		} else if (aggregate.Over != null) {
			sql += ' OVER ${RenderOver(aggregate.Over)}';
		}
		return sql;
	}

	function RenderWindowDefinition(window:NamedWindowSqlSource):String {
		final parts = [];
		if (window.PartitionBy.length > 0) {
			parts.push('PARTITION BY ${window.PartitionBy.map(RenderExpression).join(", ")}');
		}
		if (window.OrderBy.length > 0) {
			parts.push('ORDER BY ${window.OrderBy.map(RenderOrderBy).join(", ")}');
		}
		if (window.Frame != null) {
			parts.push(RenderFrame(window.Frame));
		}
		return '${window.Name} AS (${parts.join(" ")})';
	}

	/**
		The alias a column renders under. A generated column names its source by the position of the
		lambda parameter it was reached through, which is only meaningful against a statement — so
		this is where the two are put together.
	**/
	function AliasOf(source:ISqlSource):String {
		final parameter = Std.downcast(cast source, ParameterSqlSource);
		if (parameter == null) {
			return source.Alias;
		}

		final frame = scopes.length - 1 - parameter.Scope;
		if (frame < 0) {
			throw 'Nothing encloses this statement ${parameter.Scope} deep, so it has no row to name';
		}
		final within = scopes[frame];
		if (parameter.Index >= within.length) {
			throw 'That statement has ${within.length} source(s), so it has no row ${parameter.Index}';
		}
		return Named(within[parameter.Index]);
	}

	/**
		`x IS NULL` rather than `x = NULL`.

		Nothing equals NULL in SQL, not even NULL — a comparison against it is neither true nor
		false but unknown, so `= NULL` quietly matches no row at all. Written as a comparison,
		meant as a test, and rendered as one.
	**/
	function NullTest(binary:BinarySqlExpression):Null<String> {
		final negated = switch binary.Operator {
			case Equal: false;
			case NotEqual: true;
			case _: return null;
		}

		final operand = IsNull(binary.Left) ? binary.Right : (IsNull(binary.Right) ? binary.Left : null);
		if (operand == null) {
			return null;
		}
		return '${RenderExpression(operand)} IS ${negated ? "NOT NULL" : "NULL"}';
	}

	function IsNull(e:ISqlExpression):Bool {
		final constant = Std.downcast(cast e, ConstSqlExpression);
		return constant != null && constant.Value.match(SqlConstNull);
	}

	/** Parenthesise a child only where precedence needs it. */
	function Operand(parent:BinarySqlExpression, child:ISqlExpression):String {
		final nested = Std.downcast(cast child, BinarySqlExpression);
		final sql = RenderExpression(child);
		return (nested != null && Precedence(nested.Operator) < Precedence(parent.Operator)) ? '($sql)' : sql;
	}

	function Precedence(op:SqlBinaryOperator):Int {
		return switch op {
			case Or: 1;
			case And: 2;
			case Equal | NotEqual | LessThan | LessThanOrEqual | GreaterThan | GreaterThanOrEqual: 3;
			case Add | Subtract: 4;
			case Multiply | Divide | Modulo: 5;
		}
	}

	function RenderOperator(op:SqlBinaryOperator):String {
		return switch op {
			case Equal: "=";
			case NotEqual: "<>";
			case LessThan: "<";
			case LessThanOrEqual: "<=";
			case GreaterThan: ">";
			case GreaterThanOrEqual: ">=";
			case And: "AND";
			case Or: "OR";
			case Add: "+";
			case Subtract: "-";
			case Multiply: "*";
			case Divide: "/";
			case Modulo: "%";
		}
	}

	function RenderConst(value:SqlConstValue):String {
		return switch value {
			case SqlConstBool(v): v ? "1" : "0";
			case SqlConstInt(v): Std.string(v);
			case SqlConstFloat(v): Std.string(v);
			case SqlConstString(v): "'" + StringTools.replace(v, "'", "''") + "'";
			case SqlConstDate(v): "'" + DateTools.format(v, "%Y-%m-%d %H:%M:%S") + "'";
			case SqlConstNull: "NULL";
		}
	}

	// ---- functions, dates and spans ----------------------------------------------------------

	public function OnStringOperation(e:StringOperationExpression):String {
		return FunctionRendering.StringOperation(e, this);
	}

	public function OnDateOperation(e:DateOperationSqlExpression):String {
		return FunctionRendering.DateOperation(e, this);
	}

	public function OnDateFormat(e:DateFormatSqlExpression):String {
		return FunctionRendering.DateFormat(e, this);
	}

	public function OnInterval(e:IntervalSqlExpression):String {
		return FunctionRendering.Interval(e);
	}
}
