package codequery.queries;

/** A row refused before it was sent, because a value would not fit its column — C#'s `ArgumentException`. */
class InsertRefused {
	public final Message:String;

	public function new(message:String) {
		this.Message = message;
	}

	public function toString():String {
		return Message;
	}
}
