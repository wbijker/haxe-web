package codequery.migrations;

import codequery.sqlexpressions.SchemaChangeExpression;

/** A function, procedure, view or trigger as the schema records it: its kind, its name, and its SQL. */
class DatabaseRoutineDefinition {
	public var Kind:DatabaseRoutineKind;
	public var Name:String;
	public var Schema:Null<String> = null;
	public var Body:Null<String> = null;
	public var Materialized:Bool = false;

	/** Created by the application when it runs rather than carried by a migration. */
	public var Inline:Bool = false;

	public var ReturnType:Null<String> = null;

	/** For a trigger, the table it fires on. */
	public var TableName:Null<String> = null;

	public function new(?kind:DatabaseRoutineKind, name:String = "", ?body:String, ?schema:String) {
		this.Kind = kind == null ? View : kind;
		this.Name = name;
		this.Body = body;
		this.Schema = schema;
	}

	public function Clone():DatabaseRoutineDefinition {
		final copy = new DatabaseRoutineDefinition(Kind, Name, Body, Schema);
		copy.Materialized = Materialized;
		copy.Inline = Inline;
		copy.ReturnType = ReturnType;
		copy.TableName = TableName;
		return copy;
	}
}
