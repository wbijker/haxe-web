package codequery.migrations;

import codequery.sqlexpressions.TablePartition;
#if macro
import codequery.sqlexpressions.ColumnsBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/**
	Strongly-typed table partitioning: a key named by a lambda over the entity, bounds typed to the
	key, rendered as PostgreSQL's declarative partitioning. The C# `DbTablePartition<T>`.

	```haxe
	class SalesByYear extends DbTablePartition<Sale> {
		override function Configure(config:IPartitionConfig<Sale>) {
			config.PartitionBy(s -> s.saleDate).AsRange()
				.Add("sales_2024", new Date(2024, 0, 1, 0, 0, 0), new Date(2025, 0, 1, 0, 0, 0));
		}
	}
	```
**/
class DbTablePartition<T> {
	public function new() {}

	public function Configure(config:IPartitionConfig<T>):Void {}

	/** The partition, built by running `Configure`. */
	public function Build():TablePartition {
		final config = new IPartitionConfig<T>();
		Configure(config);
		if (config.Key == null) {
			throw "Configure must call PartitionBy to name the partition key.";
		}
		return config.Key.Build();
	}
}

/** What `Configure` is handed: the one call that names the key. */
class IPartitionConfig<T> {
	public var Key:Null<PartitionKeyBuilder> = null;

	public function new() {}

	/**
		The key: a column, or the year of a date column — `s -> s.saleDate`, `s -> Sql.Year(s.saleDate)`.
		Nothing here is SQL text; the lambda is read while compiling and rendered as the key expression.
	**/
	public macro function PartitionBy(self:Expr, key:Expr):Expr {
		final entity = switch Context.typeof(self).follow() {
			case TInst(_, [row]): row;
			case t: Context.error('${t.toString()} is not a partition config', self.pos);
		}
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', key.pos);
		}
		final body = switch key.expr {
			case EFunction(_, {expr: {expr: EReturn(e)}}): e;
			case EFunction(_, {expr: e}): e;
			case _: Context.error("Expected a lambda over the entity, e.g. s -> s.saleDate", key.pos);
		}
		return macro $self.KeyExpression($v{Render(row, body)});
	}

	#if macro
	static function Render(row:ClassType, e:Expr):String {
		return switch e.expr {
			case EField(_, name): ColumnOf(row, name, e.pos);
			case ECall({expr: EField({expr: EConst(CIdent("Sql"))}, part)}, [inner])
				if (part == "Year" || part == "Month" || part == "Day"):
				'EXTRACT(${part.toUpperCase()} FROM ${Render(row, inner)})';
			case EParenthesis(inner) | EMeta(_, inner) | EReturn(inner): Render(row, inner);
			case EBlock([inner]): Render(row, inner);
			case _: Context.error("A partition key is a column, or the year, month or day of a date column", e.pos);
		}
	}

	static function ColumnOf(row:ClassType, name:String, pos:Position):String {
		for (field in row.fields.get()) {
			if (field.name == name) {
				return ColumnsBuilder.ColumnNameOf(field);
			}
		}
		return Context.error('${row.name} has no field $name', pos);
	}
	#end

	public function KeyExpression(expression:String):PartitionKeyBuilder {
		Key = new PartitionKeyBuilder(expression);
		return Key;
	}
}

/** The key named; what follows says how it is split. */
class PartitionKeyBuilder {
	public final KeyExpression:String;
	var strategy:Null<PartitionStrategy> = null;
	final partitions:Array<PartitionDefinition> = [];
	var count:Null<Int> = null;

	/** The table this partitions, where it is configured on a column of one rather than built apart. */
	var into:Null<DatabaseTableDefinition> = null;

	public function new(keyExpression:String) {
		this.KeyExpression = keyExpression;
	}

	/** Keeps `table.Partition` current with every step said here — `Column(...).PartitionBy()`. */
	public function Into(table:DatabaseTableDefinition):PartitionKeyBuilder {
		into = table;
		Sync();
		return this;
	}

	function Sync():Void {
		if (into != null && strategy != null) {
			into.Partition = Build();
		}
	}

	public function AsRange():RangePartitions {
		strategy = Range;
		Sync();
		return new RangePartitions(this);
	}

	public function AsList():ListPartitions {
		strategy = List;
		Sync();
		return new ListPartitions(this);
	}

	public function AsHash():HashPartitions {
		strategy = Hash;
		Sync();
		return new HashPartitions(this);
	}

	public function AddPartition(partition:PartitionDefinition):Void {
		partitions.push(partition);
		Sync();
	}

	public function Sized(partitions:Int):Void {
		count = partitions;
		Sync();
	}

	public function Build():TablePartition {
		if (strategy == null) {
			throw "PartitionBy needs AsRange, AsList or AsHash after it.";
		}
		return new TablePartition(KeyExpression, strategy, partitions, count);
	}

	/** A bound as SQL: a date in full, a number bare, anything else quoted. */
	public static function Literal(value:Dynamic):String {
		if (Std.isOfType(value, Date)) {
			return "'" + DateTools.format(value, "%Y-%m-%d %H:%M:%S") + "'";
		}
		return SqlLiteral.Format(value);
	}
}

class RangePartitions {
	final key:PartitionKeyBuilder;

	public function new(key:PartitionKeyBuilder) {
		this.key = key;
	}

	public function Add(name:String, from:Dynamic, to:Dynamic):RangePartitions {
		key.AddPartition(new PartitionDefinition(name, PartitionKeyBuilder.Literal(from), PartitionKeyBuilder.Literal(to)));
		return this;
	}
}

class ListPartitions {
	final key:PartitionKeyBuilder;

	public function new(key:PartitionKeyBuilder) {
		this.key = key;
	}

	public function Add(name:String, values:Array<Dynamic>):ListPartitions {
		key.AddPartition(new PartitionDefinition(name, null, null, [for (v in values) PartitionKeyBuilder.Literal(v)]));
		return this;
	}
}

class HashPartitions {
	final key:PartitionKeyBuilder;

	public function new(key:PartitionKeyBuilder) {
		this.key = key;
	}

	public function Partitions(count:Int):HashPartitions {
		key.Sized(count);
		return this;
	}
}
