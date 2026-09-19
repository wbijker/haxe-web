package suites;

import codequery.Char;
import codequery.Decimal;
import codequery.Guid;
import codequery.inspection.SchemaInspector;
import codequery.migrations.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/**
	`PropertyInitializerDefaultTests.cs` — a property initializer is a default the entity already
	states: the column is declared `DEFAULT 42`.
**/
class PropertyInitializerDefaultTests extends TestCase {
	static function DefaultOf(definition:DatabaseTableDefinition, column:String):String {
		final value = definition.Columns.single(c -> c.Name == column).DefaultValue;
		return value == null ? "<none>" : value;
	}

	function testAnInitializedProperty_DeclaresTheColumnsDefault() {
		final declared = SchemaInspector.FromType(PidDeclared);
		Assert.equals("42", DefaultOf(declared, "value"));
		Assert.equals("900000000", DefaultOf(declared, "big"));
		Assert.equals("1.5", DefaultOf(declared, "rate"));
		Assert.equals("TRUE", DefaultOf(declared, "live"));
		Assert.equals("'n/a'", DefaultOf(declared, "note"));
		Assert.equals("'A'", DefaultOf(declared, "grade"));
		// An enum is stored as its number, so that is what the default has to be.
		Assert.equals("2", DefaultOf(declared, "state"));
		Assert.equals("7", DefaultOf(declared, "optional"));
	}

	function testTheDefaultReachesTheDdl_InEachDialectsSpelling() {
		Assert.skip("PostgresSqlDriver: dialect spelling of the CREATE TABLE");
	}

	function testAPropertyLeftAtItsTypesDefault_DeclaresNothing() {
		final silent = SchemaInspector.FromType(PidSilent);
		Assert.equals("<none>", DefaultOf(silent, "value"));
		Assert.equals("<none>", DefaultOf(silent, "live"));
		Assert.equals("<none>", DefaultOf(silent, "note"));
	}

	/** A value that would differ next run is not a default a migration can hold. */
	function testAValueThatWouldDifferNextRun_IsNotADefaultTheSchemaHolds() {
		final moving = SchemaInspector.FromType(PidMoving);
		Assert.equals("<none>", DefaultOf(moving, "created"));
		Assert.equals("<none>", DefaultOf(moving, "token"));
	}

	function testAGeneratedKey_TakesNoDefault_WhateverThePropertySays() {
		final keyed = SchemaInspector.FromType(PidKeyWithValue);
		Assert.equals("<none>", DefaultOf(keyed, "id"));
		Assert.equals("'x'", DefaultOf(keyed, "name"));
	}

	function testAFluentDefault_WinsOverTheInitializer() {
		final definition = SchemaInspector.FromType(PidDeclared);
		new EntityTableBuilder<PidDeclared>(definition).Column(x -> x.value).Default(() -> 7);

		Assert.equals("7", definition.Columns.single(c -> c.Name == "value").DefaultValue);
	}

	function testAConvertedColumn_CarriesTheDefaultThroughTheConversion() {
		final definition = SchemaInspector.FromType(PidDeclared);
		new EntityTableBuilder<PidDeclared>(definition)
			.Column(x -> x.state)
			.Convert((s:PidStatus) -> PidStatusNames.NameOf(s), (s:String) -> PidStatusNames.Parse(s));

		// Stored as text now, so the default is the text — not the 2 the enum column would have taken.
		Assert.equals("'Closed'", definition.Columns.single(c -> c.Name == "state").DefaultValue);
	}

	function testARowStillCarryingTheDeclaredDefault_LetsTheDatabaseWriteIt() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testARowThatSetsTheColumn_KeepsWhatItSet_AndZeroIsTheAbsenceOfOne() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testWhereTheColumnAndTheInitializerDisagree_TheRowIsWhatIsWritten() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testANullIsSent_EvenWhereTheColumnHasADefault() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testTheColumnIsLeftOutOfTheStatement_RatherThanSentAsTheSameValue() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}

private enum abstract PidStatus(Int) {
	var Unknown = 0;
	var Active = 1;
	var Closed = 2;
}

private class PidStatusNames {
	public static function NameOf(s:PidStatus):String {
		return switch s {
			case Active: "Active";
			case Closed: "Closed";
			case _: "Unknown";
		}
	}

	public static function Parse(s:String):PidStatus {
		return switch s {
			case "Active": Active;
			case "Closed": Closed;
			case _: Unknown;
		}
	}
}

@tableName("t")
private class PidDeclared {
	public var id:Int = 0;
	public var value:Int = 42;
	// A `long` in C#; Haxe has no constant an Int64 field could be initialised with.
	public var big:Int = 900000000;
	public var rate:Decimal = 1.5;
	public var live:Bool = true;
	public var note:String = "n/a";
	public var grade:Char = "A";
	public var state:PidStatus = Closed;
	public var optional:Null<Int> = 7;

	public function new() {}
}

@tableName("t")
private class PidSilent {
	public var id:Int = 0;
	public var value:Int; // no initializer — nothing to declare
	public var live:Bool = false; // the type's default said twice is still nothing to declare
	public var note:Null<String>;

	public function new() {}
}

@tableName("t")
private class PidMoving {
	public var id:Int = 0;
	public var created:Date = Date.now();
	public var token:Guid = Guid.newGuid();

	public function new() {}
}

@tableName("t")
private class PidKeyWithValue {
	public var id:Int = 5;
	public var name:String = "x";

	public function new() {}
}
