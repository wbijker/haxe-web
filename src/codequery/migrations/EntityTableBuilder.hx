package codequery.migrations;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Strongly-typed configuration of one entity's table — what a `DbTable.of(t -> …)` lambda is
	handed. Configuration goes through a column: `Column(x -> x.property)` names it once, and its
	type, facets and constraints hang off the builder that returns. What is left here belongs to
	no column at all: a `Check` spanning columns.
**/
class EntityTableBuilder<TEntity> {
	/** The table as it currently stands, which everything here amends. */
	public final Definition:DatabaseTableDefinition;

	/** The snapshot the table belongs to, when the builder came from one. */
	public final Snapshot:Null<SchemaSnapshot>;

	public function new(definition:DatabaseTableDefinition, ?snapshot:SchemaSnapshot) {
		this.Definition = definition;
		this.Snapshot = snapshot;
	}

	/** Configures the column a property maps to — the starting point for table configuration. */
	public macro function Column(self:Expr, property:Expr):Expr {
		return ColumnBuilderMacros.ColumnCall(self, property);
	}

	/** A CHECK spanning columns — `Check("CK_x", r -> r.start < r.end)`. */
	public macro function Check(self:Expr, name:Expr, expression:Expr):Expr {
		final sql = CheckExpressionRenderer.RenderEntity(expression, expression.pos);
		return macro $self.CheckSql($name, $sql);
	}

	/** What `Check` expands to. */
	public function CheckSql(name:String, expression:String):EntityTableBuilder<TEntity> {
		Definition.Check(name, expression);
		return this;
	}

	// What `Column` expands to: a builder of the kind the property's type gets.

	public function StringColumn(name:String, type:DatabaseColumnType, nullable:Bool):StringColumnBuilder<TEntity> {
		return new StringColumnBuilder<TEntity>(this, Definition, name, type, nullable);
	}

	public function BinaryColumn(name:String, type:DatabaseColumnType, nullable:Bool):BinaryColumnBuilder<TEntity> {
		return new BinaryColumnBuilder<TEntity>(this, Definition, name, type, nullable);
	}

	public function DecimalColumn<TProperty>(name:String, type:DatabaseColumnType, nullable:Bool):DecimalColumnBuilder<TEntity, TProperty> {
		return new DecimalColumnBuilder<TEntity, TProperty>(this, Definition, name, type, nullable);
	}

	public function DateTimeColumn<TProperty>(name:String, type:DatabaseColumnType, nullable:Bool):DateTimeColumnBuilder<TEntity, TProperty> {
		return new DateTimeColumnBuilder<TEntity, TProperty>(this, Definition, name, type, nullable);
	}

	public function TimeColumn<TProperty>(name:String, type:DatabaseColumnType, nullable:Bool):TimeColumnBuilder<TEntity, TProperty> {
		return new TimeColumnBuilder<TEntity, TProperty>(this, Definition, name, type, nullable);
	}

	public function PlainColumn<TProperty>(name:String, type:DatabaseColumnType, nullable:Bool, isGuid:Bool):ColumnBuilder<TEntity, TProperty> {
		return new ColumnBuilder<TEntity, TProperty>(this, Definition, name, type, nullable, isGuid);
	}
}
