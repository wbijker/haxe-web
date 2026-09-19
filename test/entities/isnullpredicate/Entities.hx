package entities.isnullpredicate;

import codequery.SqlDate;

/** The entity `IsNullPredicateTests.cs` declares. */
class Ticket {
	public var id:Int = 0;
	public var assigneeId:Null<Int>;
	public var closedDate:Null<SqlDate>;

	public function new() {}
}
