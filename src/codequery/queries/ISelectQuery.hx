package codequery.queries;

import codequery.sqlexpressions.ExpressionConverter;
#if macro
import haxe.macro.Expr;
#end

/**
	A SELECT under construction — the type every signature of the C# API names, and the type a
	caller holds.

	In C# `Where` takes an `Expression<SqlCondition<T1>>`, reified at runtime. Here it is a macro,
	so the predicate is converted during compilation. That is why this is an abstract over
	`ISelectQueryRuntime` rather than a plain interface: a macro method cannot be dispatched through
	an interface, but it can hang off an abstract while the interface underneath keeps the runtime
	contract that implementations implement. The two convert to each other implicitly, so a value of
	either can be passed wherever the other is expected.
**/
@:forward
abstract ISelectQuery<T1>(ISelectQueryRuntime<T1>) from ISelectQueryRuntime<T1> to ISelectQueryRuntime<T1> {
	/**
		`WHERE <predicate>`, e.g. `a -> a.id == 12`.

		Answers with a query of its own; the one it was asked of is unchanged.
	**/
	public macro function Where(self:Expr, predicate:Expr):Expr {
		final entity = ExpressionConverter.EntityOf(self);
		final condition = ExpressionConverter.Convert(predicate, entity);
		return macro $self.WhereCondition($condition);
	}
}
