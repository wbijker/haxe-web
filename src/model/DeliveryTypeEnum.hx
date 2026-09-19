package model;

enum abstract DeliveryTypeEnum(Int) to Int {
	var InternalDeliveryNote = 1;
	var SupplierDelivery = 2;
	var InternalAcknoledgementOfCompetion = 3;
	var AcknowledgementOfReceipt = 5;
	var Consumption = 6;
}
