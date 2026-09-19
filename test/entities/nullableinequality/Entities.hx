package entities.nullableinequality;

/** The entity `NullableInequalityTests.cs` declares. */
@tableName("tickets")
class Ticket {
	public var id:Int = 0;

	/** Nullable: a ticket need not be assigned. */
	public var assigneeId:Null<Int>;

	/** Nullable too — a string, and nothing says otherwise. */
	public var note:Null<String>;

	/** Not nullable, and says so. */
	@columnNullable(false)
	public var title:String = "";

	/** A value type, so it can never be NULL. */
	public var priority:Int = 0;

	public function new() {}
}
