import model.Delivery;
import model.DeliveryStatusEnum;
import model.DeliveryTypeEnum;

class Main {
	static function main() {
		final d = new Delivery(1, SupplierDelivery, OnHold);
		d.fromStoreId = 42;
		d.noteNo = "DN-0001";

		Sys.println('Delivery ${d.id} "${d.noteNo}"');
		Sys.println('  type   = ${d.type} (${(d.type : Int)})');
		Sys.println('  status = ${d.status} (${(d.status : Int)})');
		Sys.println('  fromStoreId = ${d.fromStoreId}, toStoreId = ${d.toStoreId}');
	}
}
