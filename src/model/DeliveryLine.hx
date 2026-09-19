package model;

/** A line of a delivery — what was sent, and how much of it. */
@tableName("delivery_line")
class DeliveryLine {
	public var id:Int;
	public var deliveryId:Int;
	public var itemCode:String = "";
	public var quantity:Int;

	public function new(id:Int, deliveryId:Int, quantity:Int) {
		this.id = id;
		this.deliveryId = deliveryId;
		this.quantity = quantity;
	}
}
