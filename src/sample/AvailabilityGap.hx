package sample;

/** The empty windows between a unit's stays — the row type of `vw_availability_gaps`. */
@tableName("vw_availability_gaps")
class AvailabilityGap {
	public var unitId:Int = 0;
	public var bookingId:Int = 0;
	public var gapStart:codequery.SqlDate;
	public var gapEnd:Null<codequery.SqlDate>;
	public var gapLength:Null<Float>;

	public function new() {}
}
