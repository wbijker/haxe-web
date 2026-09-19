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
	public var sleeps:Int = 0;

	/** The nightly rate before the weekend uplift and any length-of-stay discount. */
	public var baseRateCents:Int = 0;

	/** Charged once per stay, whatever its length. */
	public var cleaningFeeCents:Int = 0;

	public function new(id:Int) {
		this.id = id;
	}
}
