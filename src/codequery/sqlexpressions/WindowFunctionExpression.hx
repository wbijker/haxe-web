package codequery.sqlexpressions;

/**
	A window function, which only means anything over a window.

	An aggregate can be read either way — `SUM(x)` over a group or over a window — so it carries its
	window when it has one. These have no other reading, so the window is not optional.
**/
class WindowFunctionExpression implements ISqlExpression {
	public final Function:WindowFunction;
	public final Arguments:Array<ISqlExpression>;

	/** The window it reads over: one the statement named, or one written out here. */
	public final Window:Null<NamedWindowSqlSource>;
	public final Over:Null<WindowDefinition>;

	public function new(fn:WindowFunction, arguments:Array<ISqlExpression>, ?window:NamedWindowSqlSource,
			?over:WindowDefinition) {
		this.Function = fn;
		this.Arguments = arguments;
		this.Window = window;
		this.Over = over;
	}

	/** The partition of a window written out here; empty for a named one, as in the C#. */
	public var PartitionBy(get, never):Array<ISqlExpression>;

	function get_PartitionBy():Array<ISqlExpression> {
		return Over == null ? [] : Over.PartitionBy;
	}

	/** The ordering of a window written out here; empty for a named one. */
	public var OrderBy(get, never):Array<OrderByExpression>;

	function get_OrderBy():Array<OrderByExpression> {
		return Over == null ? [] : Over.OrderBy;
	}

	/** The frame of a window written out here, if it has one. */
	public var Frame(get, never):Null<WindowFrame>;

	function get_Frame():Null<WindowFrame> {
		return Over == null ? null : Over.Frame;
	}

	/** The same function, read over a window the statement named. */
	public function OverWindow(window:NamedWindowSqlSource):WindowFunctionExpression {
		return new WindowFunctionExpression(Function, Arguments, window, null);
	}

	/** The same function, read over a window written out here. */
	public function OverDefinition(over:WindowDefinition):WindowFunctionExpression {
		return new WindowFunctionExpression(Function, Arguments, null, over);
	}

	/** The same function, over a framed window. */
	public function Framed(frame:WindowFrame):WindowFunctionExpression {
		if (Over == null) {
			throw "A frame belongs to a window written out with overRows, not to a named one";
		}
		return new WindowFunctionExpression(Function, Arguments, null,
			new WindowDefinition(Over.PartitionBy, Over.OrderBy, frame));
	}
}
