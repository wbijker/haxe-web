package sample;

/**
	A rentable place. Money is held in whole cents, so every price in this sample is integer
	arithmetic — no rounding to argue about.
**/
@tableName("unit")
class Unit {
	public var id:Int;

	@columnNullable(false)
	@columnMaxLength(120)
	public var name:String = "";

	/** How many people may stay. */
	public var sleeps:Int;

	/** The nightly rate before the weekend uplift and any length-of-stay discount. */
	public var baseRateCents:Int;

	/** Charged once per stay, whatever its length. */
	public var cleaningFeeCents:Int;

	public function new(id:Int) {
		this.id = id;
	}
}
