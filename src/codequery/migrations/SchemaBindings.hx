package codequery.migrations;

import codequery.execution.DatabaseConfiguration;

/**
	What a built schema is bound to: the snapshot it was built into, and the configuration it runs
	against. A declared schema is a plain object, so this is looked up by the object rather than
	carried on it.
**/
class SchemaBindings {
	static final bindings = new haxe.ds.ObjectMap<{}, {snapshot:SchemaSnapshot, config:Null<DatabaseConfiguration>}>();

	public static function Bind(schema:{}, snapshot:SchemaSnapshot, ?config:DatabaseConfiguration):Void {
		bindings.set(schema, {snapshot: snapshot, config: config});
	}

	public static function SnapshotOf(schema:{}):Null<SchemaSnapshot> {
		final bound = bindings.get(schema);
		return bound == null ? null : bound.snapshot;
	}

	public static function ConfigOf(schema:{}):Null<DatabaseConfiguration> {
		final bound = bindings.get(schema);
		return bound == null ? null : bound.config;
	}
}
