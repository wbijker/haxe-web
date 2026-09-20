package codequery;

import codequery.migrations.SchemaSnapshot;

/** A schema member that has something to say about its table beyond what the entity declares. */
interface IDbTableMember {
	/** The entity's class path. */
	var EntityName(default, null):Null<String>;

	/** Applies what the member declares to the snapshot's table for its entity. */
	function ApplyConfiguration(snapshot:SchemaSnapshot):Void;
}
