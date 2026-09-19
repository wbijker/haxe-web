import codequery.DbTable;
import model.Delivery;
import model.DeliveryLine;
import model.Store;

/**
	The sample schema: a plain class listing one member per database object, each member
	constructing itself — the shape `CodeQuery.Sample.SampleDb` has.
**/
class SampleDb {
	public final Deliveries:DbTable<Delivery> = DbTable.of();
	public final Lines:DbTable<DeliveryLine> = DbTable.of();
	public final Stores:DbTable<Store> = DbTable.of();

	public function new() {}
}
