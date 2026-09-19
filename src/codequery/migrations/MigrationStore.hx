package codequery.migrations;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
	Migrations on disk: a folder each, named for when it was written.

	The name is what orders them and what the database records as applied, so it is a timestamp and
	a word rather than a number anyone has to keep unique.
**/
class MigrationStore {
	public final Folder:String;

	public function new(folder:String) {
		this.Folder = folder;
	}

	/** Every migration written, oldest first. */
	public function All():Array<Migration> {
		#if sys
		if (!FileSystem.exists(Folder)) {
			return [];
		}
		final names = [for (name in FileSystem.readDirectory(Folder)) if (FileSystem.isDirectory(Path(name))) name];
		names.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return [for (name in names) Read(name)];
		#else
		return [];
		#end
	}

	/** The schema the last migration left, or nothing where there are none. */
	public function LatestSnapshot():DatabaseSchema {
		final written = All();
		return written.length == 0 ? DatabaseSchema.Empty() : SchemaSnapshot.FromYaml(written[written.length - 1].Snapshot);
	}

	public function Write(migration:Migration):String {
		#if sys
		final folder = Path(migration.Name);
		FileSystem.createDirectory(folder);
		File.saveContent('$folder/up.sql', migration.Up);
		File.saveContent('$folder/down.sql', migration.Down);
		File.saveContent('$folder/snapshot.yaml', migration.Snapshot);
		return folder;
		#else
		throw "Migrations are written to disk, which this target has none of";
		#end
	}

	/** A name that sorts by when it was written: `20260919T142530_initial`. */
	public static function NameFor(description:String):String {
		final now = Date.now();
		return DateTools.format(now, "%Y%m%dT%H%M%S") + "_" + description;
	}

	#if sys
	function Read(name:String):Migration {
		final folder = Path(name);
		return new Migration(name, Content('$folder/up.sql'), Content('$folder/down.sql'),
			FileSystem.exists('$folder/snapshot.yaml') ? Content('$folder/snapshot.yaml') : Content('$folder/snapshot.yml'));
	}

	function Content(file:String):String {
		return FileSystem.exists(file) ? File.getContent(file) : "";
	}
	#end

	function Path(name:String):String {
		return '$Folder/$name';
	}
}
