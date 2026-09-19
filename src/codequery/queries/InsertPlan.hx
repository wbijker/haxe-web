package codequery.queries;

import codequery.InsertStrategy;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.InsertExpression;

/**
	What an insert given a strategy does beyond building its statement: carries the strategy on it,
	checks the rows where asked to, and refuses now what the strategy could not do later.
**/
class InsertPlan {
	public static function Apply(statement:InsertExpression, strategy:InsertStrategy, table:QualifiedTableName,
			entity:String, key:Null<KeyColumn>, rules:Array<ColumnRule>, rows:Array<Array<Dynamic>>):InsertExpression {
		statement.Strategy = strategy;
		if (strategy.PopulatePrimaryKey && key != null && key.Composite) {
			throw '$entity has a composite primary key, which reading one generated key back cannot correlate '
				+ 'to its row. Insert without PopulatePrimaryKey.';
		}
		if (strategy.Keys == PrimaryKeyResync) {
			KeyResync.Require(entity, key);
		}
		if (strategy.ValidationCheck) {
			InsertValidation.Check(rows, rules, table, entity);
		}
		return statement;
	}
}
