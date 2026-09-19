package codequery;

/**
	An insert that has chosen the database's own bulk-load protocol — C#'s `BulkStrategy`.

	Nothing here streams: what this port keeps is that it is an `InsertStrategy`, and so carries
	the same answer as any other about where the keys come from.
**/
class BulkStrategy extends InsertStrategy {
	public function new() {
		super();
		ValueMode = BinaryCopy;
	}
}
