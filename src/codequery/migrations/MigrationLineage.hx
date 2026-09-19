package codequery.migrations;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

/** A migration whose recorded base no longer matches the migration before it — a fork. */
class StaleMigration {
	public final Id:String;
	public final PreviousId:Null<String>;

	public function new(id:String, previousId:Null<String>) {
		this.Id = id;
		this.PreviousId = previousId;
	}
}

/** Raised when the migrations do not form a single linear chain. */
class StaleMigrationException {
	public final Message:String;
	public final Stale:Array<StaleMigration>;

	public function new(message:String, stale:Array<StaleMigration>) {
		this.Message = message;
		this.Stale = stale;
	}

	public function toString():String {
		return Message;
	}
}

/**
	Checks that the migrations form one linear chain. Each migration's snapshot records the
	fingerprint of the schema it was authored against; one whose base does not match the snapshot
	before it was created in parallel on another branch, and says so loudly rather than letting the
	next diff start from the wrong base.
**/
class MigrationLineage {
	public static final SnapshotFileName = "snapshot.yaml";

	/** The fingerprint of the empty schema — the expected base of the very first migration. */
	public static function EmptyFingerprint():String {
		return SchemaCanonicalizer.Fingerprint(new SchemaSnapshot());
	}

	/**
		The migrations whose recorded base does not match the previous migration's snapshot. With
		`scope`, only those ids are reported, though the whole chain is walked. Migrations with no
		recorded base are skipped.
	**/
	public static function Detect(migrationsPath:String, ?scope:Array<String>):Array<StaleMigration> {
		final stale:Array<StaleMigration> = [];
		var expectedBase = EmptyFingerprint();
		var previousId:Null<String> = null;

		for (entry in SnapshotFiles(migrationsPath)) {
			final document = SnapshotSerializer.Deserialize(Content(entry.file));
			if (document.BaseHash != null && document.BaseHash != expectedBase && (scope == null || scope.indexOf(entry.id) >= 0)) {
				stale.push(new StaleMigration(entry.id, previousId));
			}
			expectedBase = SchemaCanonicalizer.Fingerprint(document.ToModel());
			previousId = entry.id;
		}
		return stale;
	}

	public static function ThrowIfStale(migrationsPath:String, ?scope:Array<String>):Void {
		final stale = Detect(migrationsPath, scope);
		if (stale.length == 0) {
			return;
		}
		final ids = [for (s in stale) s.Id].join(", ");
		final one = stale.length == 1;
		throw new StaleMigrationException('Parallel migrations detected: $ids ${one ? "was" : "were"} created against a schema that no '
			+ 'longer matches the migration before ${one ? "it" : "them"} — most likely two migrations were authored on separate '
			+ 'branches and merged. Run \'reconcile\' to regenerate the affected migration against the current schema before continuing.',
			stale);
	}

	/** The migration folders that carry a snapshot, oldest first. */
	public static function SnapshotFiles(migrationsPath:String):Array<{id:String, folder:String, file:String}> {
		#if sys
		if (!FileSystem.exists(migrationsPath)) {
			return [];
		}
		final names = [for (name in FileSystem.readDirectory(migrationsPath)) if (FileSystem.isDirectory('$migrationsPath/$name')) name];
		names.sort(SchemaCanonicalizer.Compare);
		return [
			for (name in names)
				if (FileSystem.exists('$migrationsPath/$name/$SnapshotFileName'))
					{id: name, folder: '$migrationsPath/$name', file: '$migrationsPath/$name/$SnapshotFileName'}
		];
		#else
		return [];
		#end
	}

	static function Content(file:String):String {
		#if sys
		return File.getContent(file);
		#else
		return "";
		#end
	}
}
