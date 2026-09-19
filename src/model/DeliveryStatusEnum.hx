package model;

enum abstract DeliveryStatusEnum(Int) to Int {
	@display("Draft") var Draft = 1;
	@display("Issued") var Issued = 2;
	@display("Received") var Received = 3;
	@display("Completed") var Completed = 4;
	@display("Closed") var Closed = 5;
	@display("On Hold") var OnHold = 6;
	@display("Cancelled") var Cancelled = 7;
}
