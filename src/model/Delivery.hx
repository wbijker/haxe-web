package model;

@tableName("delivery")
class Delivery {
	public var id:Int;
	public var fromStoreId:Null<Int>;
	public var toStoreId:Null<Int>;
	public var destinationStoreId:Null<Int>;
	public var type:DeliveryTypeEnum;
	public var status:DeliveryStatusEnum;
	public var issuedByUserId:Null<Int>;
	public var receivedByUserId:Null<Int>;
	public var purchaseOrderId:Null<Int>;
	public var noteNo:String = "";

	public function new(id:Int, type:DeliveryTypeEnum, status:DeliveryStatusEnum) {
		this.id = id;
		this.type = type;
		this.status = status;
	}
}
