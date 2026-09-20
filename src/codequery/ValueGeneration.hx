package codequery;

/** How a primary-key value is produced — by the database, or by the application before the INSERT. */
enum ValueGeneration {
	/** The database generates the key (identity / sequence / auto-increment). */
	ServerGenerated;

	/** The application supplies the key before the INSERT. */
	ClientGenerated;
}
