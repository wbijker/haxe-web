package codequery.sqlexpressions;

enum PartitionStrategy {
	Range;
	List;
	Hash;
}

/** One child partition: a range's bounds, a list's values, or a hash's slot. */
class PartitionDefinition {
	public final Name:String;
	public final From:Null<String>;
	public final To:Null<String>;
	public final Values:Null<Array<String>>;
	public final Modulus:Null<Int>;
	public final Remainder:Null<Int>;

	public function new(name:String, ?from:String, ?to:String, ?values:Array<String>, ?modulus:Int, ?remainder:Int) {
		this.Name = name;
		this.From = from;
		this.To = to;
		this.Values = values;
		this.Modulus = modulus;
		this.Remainder = remainder;
	}
}

/** How a table is partitioned: the key expression, the strategy, and the partitions themselves. */
class TablePartition {
	public final KeyExpression:String;
	public final Strategy:PartitionStrategy;
	public final Partitions:Array<PartitionDefinition>;

	/** For a hash partition sized by count rather than listed. */
	public final Count:Null<Int>;

	public function new(keyExpression:String, strategy:PartitionStrategy, partitions:Array<PartitionDefinition>, ?count:Int) {
		this.KeyExpression = keyExpression;
		this.Strategy = strategy;
		this.Partitions = partitions;
		this.Count = count;
	}
}
