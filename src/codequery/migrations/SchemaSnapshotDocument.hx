package codequery.migrations;

/**
	The full schema state after a migration, as `snapshot.yaml` holds it: the schema, and the
	fingerprint of the schema the migration was authored against — the lineage link that lets a
	parallel migration be detected. The hash is not part of the schema, so it never affects a diff.
**/
class SchemaSnapshotDocument {
	public var Version:Int = 1;
	public var BaseHash:Null<String> = null;
	public var Schema:DatabaseSchema;

	public function new(?schema:DatabaseSchema) {
		this.Schema = schema == null ? DatabaseSchema.Empty() : schema;
		this.Version = this.Schema.Version;
	}

	public static function FromModel(schema:DatabaseSchema):SchemaSnapshotDocument {
		return new SchemaSnapshotDocument(schema);
	}

	public function ToModel():DatabaseSchema {
		Schema.Version = Version;
		return Schema;
	}
}
