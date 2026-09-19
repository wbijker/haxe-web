import sql.Query;

class Main {
	static function main() {
		// Each of these is translated during compilation: what survives into the
		// generated code is the string on the right, nothing else.
		log("d -> d.id > 10", Query.where(d -> d.id > 10));
		log("d -> d.noteNo == \"DN-0001\"", Query.where(d -> d.noteNo == "DN-0001"));
		log("d -> d.id > 10 && d.noteNo != \"\"", Query.where(d -> d.id > 10 && d.noteNo != ""));

		// Parentheses appear only where precedence actually needs them.
		log("d -> (d.id < 5 || d.id > 100) && d.toStoreId == 3", Query.where(d -> (d.id < 5 || d.id > 100) && d.toStoreId == 3));

		Sys.println("");
		Sys.println('SELECT * FROM Delivery d WHERE ${Query.where(d -> d.id > 10)}');
	}

	static function log(predicate:String, sql:String) {
		Sys.println('$predicate\n  -> $sql');
	}
}
