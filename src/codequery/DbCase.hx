package codequery;

/**
	`CASE` written out, where a ternary would not read well or has no operand to test:

	```haxe
	DbCase.When(s.id < 10, s.total).When(s.id < 20, s.total * 2).Else(s.total * 3)
	DbCase.On(p.grade).When("A", 1).When("B", 2).End()
	```

	As with `Sql`, nothing here runs: the chain is read while compiling and becomes a
	`CaseSqlExpression`. It is here so the lambda type-checks, and so the names read as C#'s.
**/
extern class DbCase {
	/** A searched CASE: `WHEN <condition> THEN <result>`, tested arm by arm. */
	public static function When<T>(condition:Bool, then:T):CaseBuilder<T>;

	/** A simple CASE: `CASE <operand> WHEN <value> THEN <result>`, compared arm by arm. */
	public static function On<TOperand>(operand:TOperand):SimpleCase<TOperand>;
}

/** The arms of a searched CASE, and how it ends. */
extern class CaseBuilder<T> {
	public function When(condition:Bool, then:T):CaseBuilder<T>;

	/** `ELSE <otherwise> END`. */
	public function Else(otherwise:T):T;

	/** `END` with no ELSE — null where no arm holds. */
	public function End():Null<T>;
}

/** A simple CASE that has its operand and needs its first arm. */
extern class SimpleCase<TOperand> {
	public function When<TResult>(value:TOperand, then:TResult):SimpleCaseBuilder<TOperand, TResult>;
}

/** The arms of a simple CASE, and how it ends. */
extern class SimpleCaseBuilder<TOperand, TResult> {
	public function When(value:TOperand, then:TResult):SimpleCaseBuilder<TOperand, TResult>;

	/** `ELSE <otherwise> END`. */
	public function Else(otherwise:TResult):TResult;

	/** `END` with no ELSE — null where no arm matches. */
	public function End():Null<TResult>;
}
