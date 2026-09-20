package codequery;

import codequery.execution.DatabaseConfiguration;
import codequery.migrations.DatabaseTableDefinition;
import codequery.migrations.SchemaSnapshot;
#if macro
import codequery.migrations.SchemaMembers;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Base class for a schema constructed with its configuration. Declare a `DbTable<T>` member per
	entity, and on `EnsureBuilt` each is inspected from its entity type and the member's own
	configuration applied; override `Configure` for what the entities cannot say.

	C# discovers the members by reflection; `EnsureBuilt` here is a macro that reads them off the
	concrete class at the call, so what is built is settled while compiling.
**/
class DbSchema implements IDbSchema {
	public final Configuration:DatabaseConfiguration;

	/** The schema as built: populated by `EnsureBuilt`, extended from `Configure`. */
	public final Schema:SchemaSnapshot;

	var built = false;

	public function new(configuration:DatabaseConfiguration) {
		this.Configuration = configuration;
		this.Schema = new SchemaSnapshot(Type.getClassName(Type.getClass(this)).split(".").pop());
	}

	/** Override to configure beyond what the entity types infer. Called once, after inspection. */
	function Configure(schema:SchemaSnapshot):Void {}

	/**
		Builds the schema on first use: inspects each declared table's entity, applies each member's
		configuration, then `Configure`. Idempotent.
	**/
	public macro function EnsureBuilt(self:Expr):Expr {
		final schema = SchemaMembers.ClassTypeOf(self);
		final members:Array<Expr> = [];
		for (table in SchemaMembers.TablesOf(schema)) {
			final path = SchemaMembers.PathOf(table.row);
			final entity = SchemaMembers.ClassExpr(table.row);
			final field = table.field.name;
			members.push(macro({
				entity: $v{path},
				definition: () -> codequery.inspection.SchemaInspector.FromType($entity),
				member: ($self.$field : codequery.IDbTableMember)
			} : codequery.SchemaMember));
		}
		final list = {expr: EArrayDecl(members), pos: self.pos};
		return macro $self.BuildWith($list);
	}

	/** What `EnsureBuilt` expands to. */
	public function BuildWith(members:Array<SchemaMember>):Void {
		if (built) {
			return;
		}
		built = true;

		for (member in members) {
			if (Schema.EntityTables.exists(member.entity)) {
				continue;
			}
			final definition = member.definition();
			Schema.Tables.push(definition);
			Schema.EntityTables.set(member.entity, definition);
		}

		// What each member declares is applied before Configure, so whole-schema configuration wins.
		for (member in members) {
			if (member.member != null) {
				member.member.ApplyConfiguration(Schema);
			}
		}

		Configure(Schema);
	}

	/** The table definition for an entity, if configured: `db.GetTableDefinition(Book)`. */
	public macro function GetTableDefinition(self:Expr, entity:Expr):Expr {
		return macro $self.Schema.TableOf($v{SchemaMembers.ClassPathOf(entity)});
	}
}

/** One table member of a schema, as `EnsureBuilt` hands it over. */
typedef SchemaMember = {
	entity:String,
	definition:Void->DatabaseTableDefinition,
	member:Null<IDbTableMember>
}
