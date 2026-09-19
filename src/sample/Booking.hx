package sample;

@tableName("booking")
class Booking {
	public var id:Int;

	@columnForeignKey("sample.Unit")
	public var unitId:Int = 0;

	@columnForeignKey("sample.Guest")
	public var guestId:Int = 0;

	public var checkIn:codequery.SqlDate;
	public var checkOut:codequery.SqlDate;
	public var status:BookingStatus;
	public var totalCents:Int = 0;
	public var refundCents:Int = 0;

	/** Flattened into this row's columns rather than a table of its own. */
	@columnObject("Flatten")
	public var price:CurrentObject = new CurrentObject();

	public function new(id:Int) {
		this.id = id;
	}

	/** The join a booking is always made to its unit by, declared once rather than at each use. */
	public static function withUnit() {
		return (b:Booking, u:Unit) -> u.id == b.unitId;
	}

	/** The same, for its guest. */
	public static function withGuest() {
		return (b:Booking, g:Guest) -> g.id == b.guestId;
	}
}
