package codequery.queries;

import codequery.InsertStrategy;
import codequery.sqldrivers.SqlTranslator;

/**
	What a load of borrowed keys owes the sequence afterwards: the table's key generator is moved
	past the highest of them, which is the collision a load otherwise leaves for whoever inserts next.
**/
class KeyResync {
	/** The statement that moves the sequence, or null where the strategy owes it nothing. */
	public static function Statement(table:QualifiedTableName, keys:Array<Dynamic>, strategy:InsertStrategy,
			entity:String, key:Null<KeyColumn>):Null<String> {
		if (strategy.Keys != PrimaryKeyResync) {
			return null;
		}
		Require(entity, key);

		var highest:Null<Int> = null;
		for (value in keys) {
			if (value == null) {
				continue;
			}
			final number:Int = value;
			if (highest == null || number > highest) {
				highest = number;
			}
		}
		if (highest == null) {
			return null;
		}
		return new SqlTranslator().BuildResyncIdentitySql(table.Name, table.Schema, key.Column, highest);
	}

	/** A sequence counts, so only a key that is a number has a highest. */
	public static function Require(entity:String, key:Null<KeyColumn>):Void {
		if (key == null) {
			throw '$entity has no primary key, so there is no key generator to resync. '
				+ 'Insert with InsertKeys.PrimaryKey instead.';
		}
		if (!key.Numeric) {
			throw '$entity.${key.Member} is a ${key.TypeName}, which no sequence counts towards. '
				+ 'Insert with InsertKeys.PrimaryKey instead.';
		}
	}
}
