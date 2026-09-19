package codequery;

/** A table name and the schema it lives in, since every statement over a table needs both. */
class QualifiedTableName {
	public final Schema:Null<String>;
	public final Name:String;

	public function new(name:String, ?schema:String) {
		this.Name = name;
		this.Schema = schema;
	}

	public function toString():String {
		return Schema == null ? Name : '$Schema.$Name';
	}
}
