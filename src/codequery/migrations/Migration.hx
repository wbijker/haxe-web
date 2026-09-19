package codequery.migrations;

/** One migration: what it is called, what it does, what undoes it, and the shape it leaves. */
class Migration {
	public final Name:String;
	public final Up:String;
	public final Down:String;
	public final Snapshot:String;

	public function new(name:String, up:String, down:String, snapshot:String) {
		this.Name = name;
		this.Up = up;
		this.Down = down;
		this.Snapshot = snapshot;
	}
}
