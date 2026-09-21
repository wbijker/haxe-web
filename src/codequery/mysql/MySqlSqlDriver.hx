package codequery.mysql;

import codequery.execution.IDatabaseExecutor;
import codequery.sqldrivers.SqlDriver;

/**
	The MySQL/MariaDB driver: `MySqlSqlTranslator` for the SQL, a connection to run it on —
	`CodeQuery.MySql.MySqlSqlDriver`.

	The connection string is the provider's own shape, `Server=…;Port=…;Database=…;Uid=…;Pwd=…`,
	and `BuildConnectionString` formats one from its parts. Made without one, the driver renders and
	refuses to run.

	Where the SQL goes is the one thing that is a runtime's own: on the PHP target the connection is
	PDO's, PHP's standard database layer, opened by `MySqlPdo`; on every other target there is no
	MySQL client to open, and the driver answers with no executor.
**/
class MySqlSqlDriver extends SqlDriver {
	#if php
	var executor:Null<IDatabaseExecutor>;
	#end

	/** A driver for a server, or — passed nothing — for SQL generation only. */
	public function new(?connectionString:String) {
		super(new MySqlSqlTranslator(), connectionString);
	}

	/** A driver from the server's parts, the way the C# constructor takes them. */
	public static function Of(host:String, ?database:String, ?username:String, ?password:String, port:Int = 3306,
			?sslMode:String, ?charSet:String):MySqlSqlDriver {
		return new MySqlSqlDriver(BuildConnectionString(host, database, username, password, port, sslMode, charSet));
	}

	/** Formats a connection string from its parts; null when no host is given. */
	public static function BuildConnectionString(?host:String, ?database:String, ?username:String, ?password:String,
			port:Int = 3306, ?sslMode:String, ?charSet:String, ?pooling:Bool, ?minPoolSize:Int, ?maxPoolSize:Int,
			?connectionTimeout:Int, ?defaultCommandTimeout:Int):Null<String> {
		if (host == null || host == "") {
			return null;
		}
		final parts:Array<{key:String, value:Null<String>}> = [
			{key: "Server", value: host},
			{key: "Port", value: Std.string(port)},
			{key: "Database", value: database},
			{key: "Uid", value: username},
			{key: "Pwd", value: password},
			{key: "SslMode", value: sslMode},
			{key: "CharSet", value: charSet},
			{key: "Pooling", value: pooling == null ? null : (pooling ? "true" : "false")},
			{key: "MinimumPoolSize", value: minPoolSize == null ? null : Std.string(minPoolSize)},
			{key: "MaximumPoolSize", value: maxPoolSize == null ? null : Std.string(maxPoolSize)},
			{key: "ConnectionTimeout", value: connectionTimeout == null ? null : Std.string(connectionTimeout)},
			{key: "DefaultCommandTimeout", value: defaultCommandTimeout == null ? null : Std.string(defaultCommandTimeout)},
		];
		return [for (p in parts) if (p.value != null && p.value != "") '${p.key}=${p.value}'].join(";");
	}

	override public function Executor():Null<IDatabaseExecutor> {
		#if php
		if (ConnectionString == null) {
			return null;
		}
		if (executor == null) {
			executor = codequery.runtimes.php.MySqlPdo.Connect(ConnectionString);
		}
		return executor;
		#else
		return null;
		#end
	}
}
