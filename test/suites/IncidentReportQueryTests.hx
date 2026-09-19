package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("incident_telemetry")
class IncidentTelemetry {
	@columnName("incident_slug") public var incidentSlug:String;
	@columnName("timestamp") public var timestamp:codequery.SqlDate;
	@columnName("instance_id") public var instanceId:Int;
	@columnName("type") public var type:String;
	@columnName("incident_status") public var incidentStatus:String;
	@columnName("identification") public var identification:String;

	public function new() {}
}

@tableName("trip_telemetry")
class TripTelemetry {
	@columnName("trip_number") public var tripNumber:String;
	@columnName("timestamp") public var timestamp:codequery.SqlDate;
	@columnName("instance_id") public var instanceId:Int;
	@columnName("registration_1") public var registration1:String;

	public function new() {}
}

/** The current state of an incident — the row its last event left behind. */
class LatestEvent {
	@columnName("incident_slug") public var incidentSlug:String;
	@columnName("incident_status") public var incidentStatus:String;
	@columnName("identification") public var identification:String;

	public function new() {}
}

/** When an incident was raised, and whether it was raised by a create event at all. */
class RaisedEvent {
	@columnName("incident_slug") public var incidentSlug:String;
	@columnName("raised_at") public var raisedAt:codequery.SqlDate;
	@columnName("has_create_event") public var hasCreateEvent:Bool;

	public function new() {}
}

/**
	`IncidentReportQueryTests.cs`.

	One real report, written whole: two `DISTINCT ON` CTEs, `IS DISTINCT FROM` as both a sort key
	and a projected column, an interval against the distance between two dates, a correlated
	`LEFT JOIN LATERAL`, and a CASE over the lot.

	Said the way this port says it: a CTE is `With(name, query)` in front of a query over that
	name; a projection into a typed row names its members after the columns the row reads; `NOW()
	- raised_at <= INTERVAL '3 days'` is `raised_at >= NOW() - INTERVAL '3 days'`; and a CASE of
	three branches is two ternaries. The SQL is the port's own spelling of the same statement.
**/
class IncidentReportQueryTests extends TestCase {
	static function Report():SelectExpression {
		// The last event of each incident: one row per slug, the newest first.
		final latest = Query.select(IncidentTelemetry)
			.Where(i -> i.incidentSlug != null && i.incidentSlug != "")
			.Distinct(i -> i.incidentSlug)
			.OrderBy(i -> i.incidentSlug)
			.OrderByDesc(i -> i.timestamp)
			.OrderByDesc(i -> i.instanceId)
			.Select(i -> {
				incident_slug: i.incidentSlug,
				incident_status: i.incidentStatus,
				identification: i.identification,
			});

		// The event that raised each incident: a create event if there is one — which is what the
		// sort by "type is not an Update" picks out — else the earliest event there is.
		final raised = Query.select(IncidentTelemetry)
			.Where(i -> i.incidentSlug != null && i.incidentSlug != "")
			.Distinct(i -> i.incidentSlug)
			.OrderBy(i -> i.incidentSlug)
			.OrderByDesc(i -> Sql.isDistinctFrom(i.type, "Update"))
			.OrderBy(i -> i.timestamp)
			.OrderBy(i -> i.instanceId)
			.Select(i -> {
				incident_slug: i.incidentSlug,
				raised_at: i.timestamp,
				has_create_event: Sql.isDistinctFrom(i.type, "Update"),
			});

		return Query.table(LatestEvent, "latest_event").From()
			.With("latest_event", latest)
			.With("raised_event", raised)
			.InnerJoin(Query.table(RaisedEvent, "raised_event"), (l, r) -> r.incidentSlug == l.incidentSlug)
			// The truck as it was at the moment the incident was raised: the last trip reading at
			// or before it, per incident — which is only a lateral because it reads both sides of
			// the join.
			.LeftJoinLateral((l, r) -> Query.select(TripTelemetry)
				.Where(t -> t.tripNumber == l.identification && t.timestamp <= r.raisedAt)
				.OrderByDesc(t -> t.timestamp)
				.OrderByDesc(t -> t.instanceId)
				.Limit(1))
			.Select((l, r, asof) -> {
				IncidentSlug: l.incidentSlug,
				RaisedAt: r.raisedAt,
				HasCreateEvent: r.hasCreateEvent,
				TatBand: l.incidentStatus == "Closed"
					? "Resolved"
					: (r.raisedAt >= Sql.dateSubtract(Sql.raw("NOW()"), 3, "days") ? "Within TAT" : "Overdue"),
				TruckRegistration: asof.registration1,
			})
			.ToExpression();
	}

	static function ReportSql():String {
		return new SqlTranslator().ToSql(Report());
	}

	/**
		The statement, whole. Written out rather than picked at piece by piece, because what
		matters is that this one query says all of it at once.
	**/
	function testTheReport() {
		final sql = ReportSql();
		// The three projected queries stand as their own statements, the wrapper ToExpression would
		// have put round each folded away as C# does, so the aliases run t0.. from the outer query.
		Assert.equals(
			"WITH latest_event AS ("
			+ "SELECT DISTINCT ON (t3.incident_slug) t3.incident_slug AS incident_slug, t3.incident_status AS incident_status, t3.identification AS identification"
			+ " FROM incident_telemetry AS t3"
			+ " WHERE t3.incident_slug IS NOT NULL AND t3.incident_slug IS DISTINCT FROM ''"
			+ " ORDER BY t3.incident_slug ASC, t3.timestamp DESC, t3.instance_id DESC"
			+ "), raised_event AS ("
			+ "SELECT DISTINCT ON (t4.incident_slug) t4.incident_slug AS incident_slug, t4.timestamp AS raised_at, t4.type IS DISTINCT FROM 'Update' AS has_create_event"
			+ " FROM incident_telemetry AS t4"
			+ " WHERE t4.incident_slug IS NOT NULL AND t4.incident_slug IS DISTINCT FROM ''"
			+ " ORDER BY t4.incident_slug ASC, t4.type IS DISTINCT FROM 'Update' DESC, t4.timestamp ASC, t4.instance_id ASC"
			+ ") "
			+ "SELECT t0.incident_slug AS IncidentSlug, t1.raised_at AS RaisedAt, t1.has_create_event AS HasCreateEvent,"
			+ " CASE WHEN t0.incident_status = 'Closed' THEN 'Resolved' ELSE CASE WHEN t1.raised_at >= NOW() - INTERVAL '3 days' THEN 'Within TAT' ELSE 'Overdue' END END AS TatBand,"
			+ " t2.registration_1 AS TruckRegistration"
			+ " FROM latest_event AS t0"
			+ " INNER JOIN raised_event AS t1 ON t1.incident_slug = t0.incident_slug"
			+ " LEFT JOIN LATERAL ("
			+ "SELECT * FROM trip_telemetry AS t5"
			+ " WHERE t5.trip_number = t0.identification AND t5.timestamp <= t1.raised_at"
			+ " ORDER BY t5.timestamp DESC, t5.instance_id DESC"
			+ " LIMIT 1"
			+ ") AS t2 ON TRUE",
			sql);
	}
}
