package sample;

@tableName("booking")
class Booking {
	public var id:Int;

	@columnForeignKey("sample.Unit")
	public var unitId:Int;

	@columnForeignKey("sample.Guest")
	public var guestId:Int;

	public var checkIn:Date;
	public var checkOut:Date;
	public var status:BookingStatus;
	public var totalCents:Int;
	public var refundCents:Int;

	/** Flattened into this row's columns rather than a table of its own. */
	@columnObject("Flatten")
	public var price:CurrentObject = new CurrentObject();

	public function new(id:Int) {
		this.id = id;
	}
}
