package codequery;

/** How the values of an insert reach the database. */
enum ValueMode {
	/** Sent beside the statement. */
	Parameterized;

	/** Written into the statement. */
	Inline;

	/** Over the database's own bulk-load protocol, where the driver can reach one. */
	BinaryCopy;
}

/** Where an insert's primary keys come from — see `InsertStrategy.Keys`. */
enum InsertKeys {
	/** The database's, wherever the row has not named one: a key left at its default asks for one. */
	Generated;

	/**
		The row's, exactly as it carries it — a data load copies rows that already have ids, and a
		row whose id is 0 is a row with id 0, not a row without one.
	**/
	PrimaryKey;

	/** The row's, and afterwards the table's key generator is moved past the highest key inserted. */
	PrimaryKeyResync;
}

/**
	How an insert is carried out.

	The rest of C#'s strategy — the batch size, whether it runs in a transaction, whether the
	generated keys are read back — is about executing, which nothing here does yet. What is here is
	what changes the statement.
**/
class InsertStrategy {
	/** Sent beside the statement by default, rather than written into it. */
	public var ValueMode:ValueMode = Parameterized;

	/** Left out by default, so the database generates them. */
	public var Keys:InsertKeys = Generated;

	/**
		Whether each row is checked against its columns before anything is sent — a string longer
		than the column holds, a decimal with more digits than it keeps, a null where the column
		refuses one. Off by default: the database checks most of this anyway, and checking twice
		costs a pass over every row. What the database cannot do is say which property and which
		row, so turn it on while finding out.
	**/
	public var ValidationCheck:Bool = false;

	/** Whether the generated keys are read back onto the rows. Read-back only: nothing here runs. */
	public var PopulatePrimaryKey:Bool = false;

	/** How many rows go into one multi-row INSERT. Zero or less puts every row in one statement. */
	public var BatchSize:Int = 1000;

	/** Whether the statements of one insert run as one transaction. */
	public var Transactional:Bool = true;

	public function new() {}
}
