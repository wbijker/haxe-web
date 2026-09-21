package codequery.mysql;

import codequery.execution.DatabaseConfiguration;

/**
	Entry point for a `DatabaseConfiguration` backed by the MySQL/MariaDB driver —
	`CodeQuery.MySql.MySqlConfiguration`.
**/
class MySqlConfiguration {
	/**
		Configuration for MySQL/MariaDB from a connection string, passed to the driver verbatim
		(`"Server=localhost;Database=app;Uid=app;Pwd=…"`). Pass nothing for SQL generation only —
		a configuration that renders but never connects.
	**/
	public static function Create(?connectionString:String):DatabaseConfiguration {
		return DatabaseConfiguration.Of(new MySqlSqlDriver(connectionString));
	}
}
