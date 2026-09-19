package entities.lateralcorrelation;

import codequery.SqlDate;

/** The entities `LateralCorrelationTests.cs` declares. */
@tableName("incidents")
class Incident {
	public var identification:String = "";
	public var raisedAt:SqlDate;
	public var take:Int = 0;

	public function new() {}
}

@tableName("trip_telemetry")
class Telemetry {
	public var tripNumber:String = "";
	public var timestamp:SqlDate;

	public function new() {}
}

@tableName("depots")
class Depot {
	public var code:String = "";

	public function new() {}
}
