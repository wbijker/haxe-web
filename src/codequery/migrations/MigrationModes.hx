package codequery.migrations;

import codequery.execution.DatabaseConfiguration;

/** Where a configuration's migrations are, settled against where the program runs. */
class MigrationModes {
	/** The migration folder as an absolute path, or null where none was named. */
	public static function ApplyPath(config:DatabaseConfiguration):Null<String> {
		final folder = config.MigrationFolder;
		if (folder == null) {
			return null;
		}
		if (haxe.io.Path.isAbsolute(folder)) {
			return folder;
		}
		#if sys
		return haxe.io.Path.normalize(haxe.io.Path.join([Sys.getCwd(), folder]));
		#else
		return folder;
		#end
	}
}
