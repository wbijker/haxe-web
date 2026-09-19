package sample;

@tableName("parts")
class Part {
	public var id:Int;

	@columnName("eng_part_no")
	@columnMaxLength(64)
	public var engPartNo:Null<String>;

	@columnName("supplier_part_no")
	@columnMaxLength(64)
	public var supplierPartNo:Null<String>;

	@columnName("manufacturer_part_no")
	@columnMaxLength(64)
	public var manufacturerPartNo:Null<String>;

	@columnName("description")
	@columnText
	public var description:Null<String>;

	public function new(id:Int) {
		this.id = id;
	}
}
