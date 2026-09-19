import codequery.DbTable;
import model.Delivery;

/**
	The sample schema: a plain class listing one member per database object, each member
	constructing itself — the shape `CodeQuery.Sample.SampleDb` has.
**/
class SampleDb {
	public final Deliveries:DbTable<Delivery> = DbTable.of();

	public function new() {}
}
