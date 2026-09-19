package codequery.migrations;

import codequery.migrations.DatabaseColumnType;

/** A composite or enum type of the database's own, as the schema records it. */
class DatabaseObjectTypeDefinition {
	public var Name:String;
	public var Schema:Null<String> = null;
	public var Fields:Array<DatabaseColumnDefinition> = [];
	public var EnumValues:Null<Array<String>> = null;
	public var IsDomain:Bool = false;

	public function new(name:String = "", ?fields:Array<DatabaseColumnDefinition>) {
		this.Name = name;
		if (fields != null) {
			this.Fields = fields;
		}
	}

	public function Equals(other:DatabaseObjectTypeDefinition):Bool {
		if (other == null || Name != other.Name || Schema != other.Schema || IsDomain != other.IsDomain
			|| Fields.length != other.Fields.length
			|| Std.string(EnumValues) != Std.string(other.EnumValues)) {
			return false;
		}
		for (index in 0...Fields.length) {
			if (!Fields[index].Matches(other.Fields[index])) {
				return false;
			}
		}
		return true;
	}

	public function Clone():DatabaseObjectTypeDefinition {
		final copy = new DatabaseObjectTypeDefinition(Name, [for (f in Fields) f.Clone()]);
		copy.Schema = Schema;
		copy.EnumValues = EnumValues == null ? null : EnumValues.copy();
		copy.IsDomain = IsDomain;
		return copy;
	}
}
