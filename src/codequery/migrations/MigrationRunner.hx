package codequery.migrations;

import codequery.execution.DatabaseConfiguration;
import codequery.migrations.IMigrationPrompt;
import codequery.sqldrivers.ISqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.SqlConstValue;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

/** What `MigrationRunner.AddMigration` wrote, and where. */
class AddMigrationResult {
	public final HasChanges:Bool;
	public final MigrationName:Null<String>;
	public final MigrationDirectory:Null<String>;
	public final UpFilePath:Null<String>;
	public final DownFilePath:Null<String>;
	public final SnapshotFilePath:Null<String>;

	public function new(hasChanges:Bool, ?name:String, ?folder:String, ?up:String, ?down:String, ?snapshot:String) {
		this.HasChanges = hasChanges;
		this.MigrationName = name;
		this.MigrationDirectory = folder;
		this.UpFilePath = up;
		this.DownFilePath = down;
		this.SnapshotFilePath = snapshot;
	}
}

/**
	Applies migrations, and remembers which it has.

	What it remembers lives in the database, in a table of its own — the only way a migration can
	know whether it has already run somewhere it did not write.
**/
class MigrationRunner {
	public static final Table = "__codequery_migrations";

	final config:DatabaseConfiguration;
	final store:MigrationStore;

	public function new(config:DatabaseConfiguration, store:MigrationStore) {
		this.config = config;
		this.store = store;
	}

	/** The migrations written but not yet applied, oldest first. */
	public function Pending():Array<Migration> {
		final applied = Applied();
		return store.All().filter(migration -> applied.indexOf(migration.Name) < 0);
	}

	/** The names of those already applied. */
	public function Applied():Array<String> {
		EnsureTable();
		return [
			for (row in config.Fetch(Raw('SELECT name FROM $Table ORDER BY name')))
				Std.string(row.get("name"))
		];
	}

	/** Applies every pending migration, in order, and answers with what it applied. */
	public function Run():Array<String> {
		final ran:Array<String> = [];
		for (migration in Pending()) {
			for (statement in Statements(migration.Up)) {
				config.Execute(Raw(statement));
			}
			config.Execute(Raw('INSERT INTO $Table (name) VALUES (\'${migration.Name}\')'));
			ran.push(migration.Name);
		}
		return ran;
	}

	/** Undoes the last applied migration. */
	public function Rollback():Null<String> {
		final applied = Applied();
		if (applied.length == 0) {
			return null;
		}

		final last = applied[applied.length - 1];
		for (migration in store.All()) {
			if (migration.Name != last) {
				continue;
			}
			for (statement in Statements(migration.Down)) {
				config.Execute(Raw(statement));
			}
			config.Execute(Raw('DELETE FROM $Table WHERE name = \'$last\''));
			return last;
		}
		return null;
	}

	// ---- scaffolding: what the C# `MigrationRunner` statics do, against a folder and a translator ----

	public static final UpFileName = "up.sql";
	public static final DownFileName = "down.sql";
	public static final SnapshotFileName = "snapshot.yaml";

	/**
		Diffs the schema against the latest snapshot in `migrationsPath` and writes a migration folder —
		`up.sql`, `down.sql`, `snapshot.yaml` — named `{yyyyMMddHHmmss}_{name}`. With nothing changed and
		`allowEmpty` false, nothing is written but the global snapshot is kept in step.
	**/
	public static function AddMigration(schema:DatabaseSchema, migrationsPath:String, translator:ISqlTranslator,
			?prompt:IMigrationPrompt, ?previousSnapshot:DatabaseSchema, allowEmpty:Bool = false):AddMigrationResult {
		#if sys
		if (!FileSystem.exists(migrationsPath)) {
			FileSystem.createDirectory(migrationsPath);
		}
		if (prompt == null) {
			prompt = new NonInteractiveMigrationPrompt();
		}

		// Never extend a forked history — the diff base would be wrong. Reconcile first.
		MigrationLineage.ThrowIfStale(migrationsPath);

		if (previousSnapshot == null) {
			previousSnapshot = LoadLatestSnapshot(migrationsPath);
		}
		final current = SchemaSnapshot.FromSchema(schema);
		final diff = SchemaDiff.Create(previousSnapshot, current);

		if (!diff.HasChanges && !allowEmpty) {
			SyncGlobalSnapshot(migrationsPath);
			return new AddMigrationResult(false);
		}

		final plans = PlanBidirectional(previousSnapshot == null ? new SchemaSnapshot() : previousSnapshot, current, prompt);

		final timestamp = NextTimestamp(migrationsPath, Date.now());
		final humanName = diff.HasChanges ? MigrationNameGenerator.Generate(diff, previousSnapshot == null) : "Empty";
		final name = '${timestamp}_${Sanitize(humanName)}';

		final folder = '$migrationsPath/$name';
		FileSystem.createDirectory(folder);

		final upFile = '$folder/$UpFileName';
		File.saveContent(upFile, RenderSqlScript(name, "up", plans.up, translator, current));
		final downFile = '$folder/$DownFileName';
		File.saveContent(downFile, RenderSqlScript(name, "down", plans.down, translator));

		final baseHash = SchemaCanonicalizer.Fingerprint(previousSnapshot == null ? new SchemaSnapshot() : previousSnapshot);
		final snapshotFile = '$folder/$SnapshotFileName';
		File.saveContent(snapshotFile, SerializeSnapshot(current, baseHash));

		SyncGlobalSnapshot(migrationsPath);
		return new AddMigrationResult(true, name, folder, upFile, downFile, snapshotFile);
		#else
		throw "Migrations are written to disk, which this target has none of";
		#end
	}

	/** A migration only when the schema has drifted from the latest snapshot — never an empty one. */
	public static function AddMigrationIfSchemaChanged(schema:DatabaseSchema, migrationsPath:String, translator:ISqlTranslator,
			?prompt:IMigrationPrompt):AddMigrationResult {
		return AddMigration(schema, migrationsPath, translator, prompt, null, false);
	}

	/** The forward and the reverse plans, the reverse reusing the forward pass's rename decisions. */
	static function PlanBidirectional(from:DatabaseSchema, to:DatabaseSchema, prompt:IMigrationPrompt):{up:Array<SchemaChangeExpression>, down:Array<SchemaChangeExpression>} {
		final recorder = new RecordingMigrationPrompt(prompt);
		final up = MigrationPlanner.Plan(SchemaDiff.Create(from, to), recorder, true);
		final down = MigrationPlanner.Plan(SchemaDiff.Create(to, from), recorder.Inverse(), true);
		return {up: up, down: down};
	}

	/** The snapshot stored by the newest migration, or null where there are none. */
	public static function LoadLatestSnapshot(migrationsPath:String):Null<SchemaSnapshot> {
		final folders = MigrationLineage.SnapshotFiles(migrationsPath);
		return folders.length == 0 ? null : ReadSnapshot(folders[folders.length - 1].file);
	}

	public static function ReadSnapshot(file:String):SchemaSnapshot {
		#if sys
		return SchemaSnapshot.FromDatabaseSchema(SnapshotSerializer.Deserialize(File.getContent(file)).ToModel());
		#else
		return new SchemaSnapshot();
		#end
	}

	/**
		Regenerates the `up.sql` and `down.sql` of existing migrations from their snapshots, newest
		first, leaving the snapshots untouched. `last` limits it to the newest N. Answers with the
		rebuilt ids, most recent first.
	**/
	public static function RebuildMigrations(migrationsPath:String, translator:ISqlTranslator, ?last:Int, ?prompt:IMigrationPrompt):Array<String> {
		#if sys
		if (prompt == null) {
			prompt = new NonInteractiveMigrationPrompt();
		}
		final folders = MigrationLineage.SnapshotFiles(migrationsPath);
		final rebuilt:Array<String> = [];
		var index = folders.length - 1;
		while (index >= 0 && (last == null || rebuilt.length < last)) {
			final previous = index == 0 ? new SchemaSnapshot() : ReadSnapshot(folders[index - 1].file);
			final current = ReadSnapshot(folders[index].file);
			final plans = PlanBidirectional(previous, current, prompt);
			File.saveContent('${folders[index].folder}/$UpFileName', RenderSqlScript(folders[index].id, "up", plans.up, translator, current));
			File.saveContent('${folders[index].folder}/$DownFileName', RenderSqlScript(folders[index].id, "down", plans.down, translator));
			rebuilt.push(folders[index].id);
			index--;
		}
		SyncGlobalSnapshot(migrationsPath);
		return rebuilt;
		#else
		return [];
		#end
	}

	/**
		Repairs a forked history by rewriting each stale migration against the schema before it and
		the current code schema, so the chain is linear again. Answers with the rewritten ids.
	**/
	public static function ReconcileMigrations(schema:DatabaseSchema, migrationsPath:String, translator:ISqlTranslator,
			?prompt:IMigrationPrompt):Array<String> {
		#if sys
		if (prompt == null) {
			prompt = new NonInteractiveMigrationPrompt();
		}
		final stale = MigrationLineage.Detect(migrationsPath);
		if (stale.length == 0) {
			return [];
		}
		final folders = MigrationLineage.SnapshotFiles(migrationsPath);
		final current = SchemaSnapshot.FromSchema(schema);
		final reconciled:Array<String> = [];
		for (entry in stale) {
			var at = -1;
			for (index in 0...folders.length) {
				if (folders[index].id == entry.Id) {
					at = index;
				}
			}
			final previous = at <= 0 ? new SchemaSnapshot() : ReadSnapshot(folders[at - 1].file);
			// The head is rewritten to the merged code; an earlier fork keeps its own schema on the new base.
			final target = at == folders.length - 1 ? current : ReadSnapshot(folders[at].file);
			final plans = PlanBidirectional(previous, target, prompt);
			File.saveContent('${folders[at].folder}/$UpFileName', RenderSqlScript(entry.Id, "up", plans.up, translator, target));
			File.saveContent('${folders[at].folder}/$DownFileName', RenderSqlScript(entry.Id, "down", plans.down, translator));
			File.saveContent(folders[at].file, SerializeSnapshot(target, SchemaCanonicalizer.Fingerprint(previous)));
			reconciled.push(entry.Id);
		}
		SyncGlobalSnapshot(migrationsPath);
		return reconciled;
		#else
		return [];
		#end
	}

	static function SerializeSnapshot(snapshot:DatabaseSchema, baseHash:String):String {
		final document = SchemaSnapshotDocument.FromModel(SchemaCanonicalizer.Canonical(snapshot));
		document.BaseHash = baseHash;
		return SnapshotSerializer.Serialize(document);
	}

	/**
		Refreshes the global snapshot at the migrations root — a mirror of the newest migration's,
		at a stable path for source-control comparison. Removed when there are no migrations.
	**/
	public static function SyncGlobalSnapshot(migrationsPath:String):Void {
		#if sys
		final target = '$migrationsPath/$SnapshotFileName';
		final folders = MigrationLineage.SnapshotFiles(migrationsPath);
		if (folders.length == 0) {
			if (FileSystem.exists(target)) {
				FileSystem.deleteFile(target);
			}
			return;
		}
		File.saveContent(target, File.getContent(folders[folders.length - 1].file));
		#end
	}

	/**
		The text of one migration script: a header, a plain-language summary of what it does, and
		the statements. `inlined` is the schema the script leads to, whose inline routines are named
		since they are part of the schema but not of any migration.
	**/
	public static function RenderSqlScript(name:String, direction:String, operations:Array<SchemaChangeExpression>,
			translator:ISqlTranslator, ?inlined:DatabaseSchema):String {
		final out = new StringBuf();
		out.add('-- Migration: $name ($direction)\n');
		out.add('-- Generated: ${DateTools.format(Date.now(), "%Y-%m-%d %H:%M:%S")} UTC\n');
		out.add("-- This file is safe to edit. Add data backfills or custom SQL below the generated statements.\n");

		final changes = SchemaChangeDescriber.Summarize(operations);
		if (changes.length > 0) {
			out.add("--\n-- Changes:\n");
			for (change in changes) {
				out.add('--   - $change\n');
			}
		}

		final inlined_ = inlined == null ? [] : [for (r in inlined.Routines) if (r.Inline) r];
		if (inlined_.length > 0) {
			inlined_.sort((a, b) -> SchemaCanonicalizer.Compare(Std.string(a.Kind) + a.Name, Std.string(b.Kind) + b.Name));
			out.add("--\n-- Inlined (no migration carries these; the application creates them when it runs):\n");
			for (routine in inlined_) {
				out.add('--   - ${Std.string(routine.Kind).toLowerCase()} ${routine.Name}' + (routine.TableName == null ? "" : ' on ${routine.TableName}') + "\n");
			}
		}
		out.add("\n");

		for (op in operations) {
			var statement = StringTools.rtrim(translator.ToDdlSql(op, true));
			while (StringTools.endsWith(statement, ";")) {
				statement = StringTools.rtrim(statement.substr(0, statement.length - 1));
			}
			out.add(statement + ";\n\n");
		}
		return out.toString();
	}

	/**
		A 14-digit timestamp that sorts strictly after every existing migration — bumped a second past
		the latest when the clock has not advanced, so two written in one second still order.
	**/
	static function NextTimestamp(migrationsPath:String, now:Date):String {
		var candidate = DateTools.format(now, "%Y%m%d%H%M%S");
		#if sys
		if (!FileSystem.exists(migrationsPath)) {
			return candidate;
		}
		var latest:Null<String> = null;
		for (name in FileSystem.readDirectory(migrationsPath)) {
			if (name.length >= 14 && ~/^[0-9]{14}/.match(name)) {
				final stamp = name.substr(0, 14);
				if (latest == null || stamp > latest) {
					latest = stamp;
				}
			}
		}
		if (latest != null && candidate <= latest) {
			final parsed = new Date(Std.parseInt(latest.substr(0, 4)), Std.parseInt(latest.substr(4, 2)) - 1, Std.parseInt(latest.substr(6, 2)),
				Std.parseInt(latest.substr(8, 2)), Std.parseInt(latest.substr(10, 2)), Std.parseInt(latest.substr(12, 2)));
			candidate = DateTools.format(DateTools.delta(parsed, 1000), "%Y%m%d%H%M%S");
		}
		#end
		return candidate;
	}

	static function Sanitize(name:String):String {
		final cleaned = ~/[^A-Za-z0-9]/g.replace(name, "_");
		return ~/^_+|_+$/g.replace(cleaned, "");
	}

	/** The ids of the migration folders (those with an up.sql), in application order. */
	public static function MigrationIds(migrationsPath:String):Array<String> {
		#if sys
		if (!FileSystem.exists(migrationsPath)) {
			return [];
		}
		final names = [
			for (name in FileSystem.readDirectory(migrationsPath))
				if (FileSystem.isDirectory('$migrationsPath/$name') && FileSystem.exists('$migrationsPath/$name/$UpFileName')) name
		];
		names.sort(SchemaCanonicalizer.Compare);
		return names;
		#else
		return [];
		#end
	}

	function EnsureTable():Void {
		config.Execute(Raw(config.Driver.MigrationHistoryDdl(Table)));
	}

	/** A migration is a script; what runs it takes one statement at a time. */
	static function Statements(sql:String):Array<String> {
		return [
			for (statement in sql.split(";"))
				if (StringTools.trim(statement) != "") StringTools.trim(statement)
		];
	}

	/**
		SQL this port did not build — the migration's own, and the bookkeeping around it.

		A migration is written as text and kept as text, so there is no statement to render; what
		it needs is a way past the renderer, which is what this is.
	**/
	static function Raw(sql:String):RawStatement {
		return new RawStatement(sql);
	}
}
