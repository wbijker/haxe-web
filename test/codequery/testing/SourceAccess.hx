package codequery.testing;

import codequery.sqlexpressions.*;
import codequery.testing.Assert;

/**
	Which of a statement's sources a column names.

	C# binds a column to its source when the lambda is converted, so a test compares aliases. Here a
	lambda is converted while compiling and a column names its source by the position of the
	parameter it was reached through, settled against the statement when it renders — so the source
	a column means is the statement's source at that position, and that is what these look up.
**/
class SourceAccess {
	/** The position of the lambda parameter the column was reached through. */
	public static function sourceIndex(e:ISqlExpression):Int {
		return parameterSource(e).Index;
	}

	/** How many statements out the column reaches: 0 for its own, 1 for the one enclosing it. */
	public static function sourceScope(e:ISqlExpression):Int {
		return parameterSource(e).Scope;
	}

	/** The source of `select` that the column names. */
	public static function sourceOf(select:SelectExpression, e:ISqlExpression):ISqlSource {
		final index = sourceIndex(e);
		final sources = select.AllSources();
		Assert.inRange(index, 0, sources.length - 1);
		return sources[index];
	}

	/** The alias of the source of `select` that the column names — the C# `column.Source.Alias`. */
	public static function sourceAlias(select:SelectExpression, e:ISqlExpression):String {
		return sourceOf(select, e).Alias;
	}

	static function parameterSource(e:ISqlExpression):ParameterSqlSource {
		final column = SqlAssert.column(e);
		final parameter = Std.downcast(cast column.Source, ParameterSqlSource);
		if (parameter == null) {
			Assert.fail('${column.ColumnName} is bound to ${Type.getClassName(Type.getClass(column.Source))}, not to a lambda parameter');
		}
		return parameter;
	}
}
