package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DateTimeOnlyTypeTests.cs` — .NET's DateOnly/TimeOnly as column types. Haxe has one date type. */
class DateTimeOnlyTypeTests extends TestCase {
	function testConverter_MapsDateOnlyToDate_TimeOnlyToTime() {
		Assert.skip("DateOnly/TimeOnly: no date-only or time-only column type in this port (Haxe has only Date)");
	}

	function testRows_RoundTripThroughTheDatabase() {
		Assert.skip("DateOnly/TimeOnly: no date-only or time-only column type in this port; needs a database: eval has none (PHP runtime only)");
	}

	function testDdl_RendersDateAndTimeColumns() {
		Assert.skip("DateOnly/TimeOnly: no date-only or time-only column type in this port; PostgresSqlDriver/SqliteSqlDriver DDL spellings");
	}
}
