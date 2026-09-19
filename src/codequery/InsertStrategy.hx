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

/** Which keys an insert writes. */
enum InsertKeys {
	/** The database generates them, so they are left out. */
	Generated;

	/** They are written as they stand. */
	Explicit;
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

	public function new() {}
}
