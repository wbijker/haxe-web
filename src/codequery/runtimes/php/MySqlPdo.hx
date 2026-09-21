package codequery.runtimes.php;

/**
	Opens a MySQL connection the way PHP does it: through PDO, with the `mysql:` DSN its
	`pdo_mysql` extension reads.

	The driver's connection string is the provider's shape — `Server=…;Port=…;Database=…;Uid=…;
	Pwd=…` — which is what a `MySqlSqlDriver` is configured with whatever the runtime, so this is
	where it becomes PDO's `mysql:host=…;port=…;dbname=…;charset=…` plus a user and a password.
**/
class MySqlPdo {
	/** The DSN, user and password PDO takes, from a provider-style connection string. */
	public static function Parse(connectionString:String):{dsn:String, user:Null<String>, password:Null<String>} {
		final parts = new Map<String, String>();
		for (part in connectionString.split(";")) {
			final at = part.indexOf("=");
			if (at > 0) {
				parts.set(StringTools.trim(part.substr(0, at)).toLowerCase(), StringTools.trim(part.substr(at + 1)));
			}
		}
		final host = First(parts, ["server", "host", "data source"]);
		if (host == null) {
			throw 'The connection string names no server: "$connectionString"';
		}
		final dsn = ['host=$host'];
		final port = parts.get("port");
		if (port != null) {
			dsn.push('port=$port');
		}
		final database = First(parts, ["database", "initial catalog"]);
		if (database != null) {
			dsn.push('dbname=$database');
		}
		final charset = First(parts, ["charset", "character set"]);
		dsn.push('charset=${charset == null ? "utf8mb4" : charset}');
		return {
			dsn: "mysql:" + dsn.join(";"),
			user: First(parts, ["uid", "user id", "user", "username"]),
			password: First(parts, ["pwd", "password"]),
		};
	}

	/** A connected executor. The PHP target only: PDO is PHP's. */
	public static function Connect(connectionString:String):PdoExecutor {
		#if php
		final parsed = Parse(connectionString);
		return PdoExecutor.Connect(parsed.dsn, parsed.user, parsed.password);
		#else
		throw "MySqlPdo connects on the PHP target; this one is not it.";
		#end
	}

	static function First(parts:Map<String, String>, keys:Array<String>):Null<String> {
		for (key in keys) {
			if (parts.exists(key)) {
				return parts.get(key);
			}
		}
		return null;
	}
}
