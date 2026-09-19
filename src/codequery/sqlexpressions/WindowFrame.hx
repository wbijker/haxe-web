package codequery.sqlexpressions;

/** `ROWS BETWEEN … AND …` — which rows of the partition an aggregate actually reads. */
class WindowFrame {
	public final Kind:FrameKind;
	public final Start:WindowBound;
	public final End:WindowBound;

	public function new(kind:FrameKind, start:WindowBound, end:WindowBound) {
		this.Kind = kind;
		this.Start = start;
		this.End = end;
	}
}
