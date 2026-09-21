package codequery.migrations;

import codequery.execution.DatabaseConfiguration;
import codequery.sqldrivers.ISqlDriver;
import codequery.sqldrivers.ISqlTranslator;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	A schema, configured: what it looks like, where its migrations are kept, and what to run them
	against.

	The C# counterpart is `DatabaseInitializer.Build<TSchema>(config)`. The shape the entities
	describe is worked out while compiling — `SchemaBuilder.Of` does that — so what is configured
	here is only the two things that cannot be known then: the folder and the connection.
**/
class DatabaseInitializer {
	/** The shape the entities describe. */
	public final Schema:DatabaseSchema;

	/** Where migrations are written and read. */
	public final Store:MigrationStore;

	/** What to run them against, or null where the schema was configured only to be written. */
	public final Config:Null<DatabaseConfiguration>;

	final translator:ISqlTranslator;

	public function new(schema:DatabaseSchema, migrationFolder:String, translator:ISqlTranslator,
			?config:DatabaseConfiguration) {
		this.Schema = schema;
		this.Store = new MigrationStore(migrationFolder);
		this.translator = translator;
		this.Config = config;
	}

	/**
		Builds a declared schema: `DatabaseInitializer.Build(ShopDb, configuration)` — the C#
		`Build<ShopDb>(configuration)` — or from an instance, `Build(new ShopDb(3), configuration)`.

		Each `DbTable` member is inspected from its entity, the member's own configuration applied,
		then `configure` for the whole schema. The result is the schema instance; `Snapshot()` and
		`Config()` from `DbSchemaExtensions` answer with what it was built into.
	**/
	public static macro function Build(schema:Expr, ?config:Expr, ?configure:Expr):Expr {
		final made = switch schema.expr {
			case EConst(CIdent(_)) | EField(_, _, _) if (IsTypeName(schema)):
				{expr: ENew(SchemaMembers.TypePathOf(SchemaMembers.ClassTypeOf(schema)), []), pos: schema.pos};
			case _: schema;
		}
		final cls = SchemaMembers.ClassTypeOf(schema);
		final name = cls.name;

		final statements:Array<Expr> = [];
		statements.push(macro final __db = $made);
		statements.push(macro final __snapshot = new codequery.migrations.SchemaSnapshot($v{name}));
		for (table in SchemaMembers.TablesOf(cls)) {
			final entity = SchemaMembers.ClassExpr(table.row);
			final path = SchemaMembers.PathOf(table.row);
			statements.push(macro {
				final __definition = codequery.inspection.SchemaInspector.FromType($entity);
				__snapshot.Tables.push(__definition);
				__snapshot.EntityTables.set($v{path}, __definition);
			});
		}
		for (table in SchemaMembers.TablesOf(cls)) {
			final field = table.field.name;
			statements.push(macro __db.$field.ApplyConfiguration(__snapshot));
			statements.push(macro __db.$field.AttachTo(__db));
		}
		// A partition declared as a member of its own is folded into its entity's table.
		for (partition in SchemaMembers.PartitionsOf(cls)) {
			final field = partition.field.name;
			final path = SchemaMembers.PathOf(partition.row);
			statements.push(macro {
				final __partitioned = __snapshot.TableOf($v{path});
				if (__partitioned != null) {
					__partitioned.Partition = __db.$field.Build();
				}
			});
		}
		if (configure != null && !configure.expr.match(EConst(CIdent("null")))) {
			statements.push(macro($configure : codequery.migrations.SchemaSnapshot -> Void)(__snapshot));
		}
		final held = config == null ? macro null : config;
		statements.push(macro codequery.migrations.SchemaBindings.Bind(__db, __snapshot, $held));
		statements.push(macro __db);
		return {expr: EBlock(statements), pos: schema.pos};
	}

	#if macro
	static function IsTypeName(e:Expr):Bool {
		return try {
			switch Context.typeof(e) {
				case TType(_, _): true;
				case _: false;
			}
		} catch (_:Dynamic) false;
	}
	#end

	/** The same, taken whole from a driver that renders and runs. */
	public static function On(schema:DatabaseSchema, migrationFolder:String, driver:ISqlDriver):DatabaseInitializer {
		return new DatabaseInitializer(schema, migrationFolder, driver, DatabaseConfiguration.Of(driver));
	}

	/**
		What the schema has become since the last migration was written.

		Worked out from the snapshot beside that migration, not from the database — which is what
		lets a migration be scaffolded with nothing to connect to.
	**/
	public function PendingChanges():Array<SchemaChange> {
		return SchemaDiff.Between(Store.LatestSnapshot(), Schema);
	}

	/**
		Writes a migration for whatever the schema has become, and answers with it — or null where
		it has become nothing, which is the usual answer and not a failure.
	**/
	public function AddMigrationIfSchemaChanged(?description:String):Null<Migration> {
		final changes = PendingChanges();
		if (changes.length == 0) {
			return null;
		}

		final up = [for (change in changes) translator.ToDdl(change) + ";"].join("\n");
		// Undone in the reverse of the order it was done, or a table would go before its columns.
		final undone = [for (change in changes) change];
		undone.reverse();
		final down = [for (change in undone) translator.ToDdl(SchemaDiff.Reverse(change)) + ";"].join("\n");

		final migration = new Migration(MigrationStore.NameFor(description == null ? "schema" : description),
			up, down, SchemaSnapshot.ToYaml(Schema));
		Store.Write(migration);
		return migration;
	}

	/** The migrations written but not yet applied. Needs somewhere to have applied them. */
	public function PendingMigrations():Array<Migration> {
		return Runner().Pending();
	}

	/** Applies every pending migration, in order, and answers with what it applied. */
	public function RunPendingMigrations():Array<String> {
		return Runner().Run();
	}

	/** Undoes the last applied migration. */
	public function Rollback():Null<String> {
		return Runner().Rollback();
	}

	function Runner():MigrationRunner {
		if (Config == null) {
			throw "Running migrations needs a connection; this schema was configured without one.";
		}
		return new MigrationRunner(Config, Store);
	}
}
