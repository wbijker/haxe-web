package codequery.sqlexpressions;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/**
	What an insert given a strategy needs to know about its entity, read while compiling: the key
	column, and the columns worth checking a row against. C# reads both off the type at runtime.
**/
class InsertConverter {
	#if macro
	/**
		The statement, given its strategy: `InsertPlan.Apply(statement, strategy, …)` with the
		entity's key, its rules, and the rows' raw values — `entries` names an array of the entity.
	**/
	public static function Strategised(statement:Expr, table:Expr, entries:Expr, entity:Type, strategy:Expr):Expr {
		final row = RowOf(entity, entries.pos);
		final key = KeyOf(row, entries.pos);
		final rules:Array<Expr> = [];
		final reads:Array<Expr> = [];
		Rules(row, macro entry, [], [], rules, reads);

		final ruleList = {expr: EArrayDecl(rules), pos: entries.pos};
		final readList = {expr: EArrayDecl(reads), pos: entries.pos};
		return macro codequery.queries.InsertPlan.Apply($statement, $strategy, $table.Table, $v{row.name}, $key,
			$ruleList, [for (entry in $entries) ($readList : Array<Dynamic>)]);
	}

	/** `KeyResync.Statement(…)` for the rows, which says what the load owes the sequence afterwards. */
	public static function Resync(table:Expr, entries:Expr, entity:Type, strategy:Expr):Expr {
		final row = RowOf(entity, entries.pos);
		final key = KeyOf(row, entries.pos);
		final keys = switch KeyField(row) {
			case null: macro [];
			case field:
				final name = field.name;
				macro [for (entry in $entries) (entry.$name : Dynamic)];
		}
		return macro codequery.queries.KeyResync.Statement($table.Table, $keys, $strategy, $v{row.name}, $key);
	}

	static function RowOf(entity:Type, pos:Position):ClassType {
		return switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', pos);
		}
	}

	/** The key, by the convention the schema uses: the member named `id`, or the one marked as the key. */
	static function KeyField(row:ClassType):Null<ClassField> {
		for (field in row.fields.get()) {
			if (!field.isPublic || !field.kind.match(FVar(AccNormal | AccNo, _))) {
				continue;
			}
			if (field.name == "id" || field.meta.has("primaryKey") || field.meta.has("columnPrimaryKey")) {
				return field;
			}
		}
		return null;
	}

	static function KeyOf(row:ClassType, pos:Position):Expr {
		final field = KeyField(row);
		if (field == null) {
			return macro null;
		}
		final type = field.type.followWithAbstracts();
		final numeric = switch type {
			case TAbstract(_.get() => {name: "Int"}, _): true;
			case _: false;
		}
		final typeName = switch type {
			case TAbstract(t, _): t.get().name;
			case TInst(t, _): t.get().name;
			case t: t.toString();
		}
		final marked = row.fields.get().filter(f -> f.meta.has("primaryKey") || f.meta.has("columnPrimaryKey")).length;
		return macro new codequery.queries.KeyColumn($v{field.name}, $v{ColumnsBuilder.ColumnNameOf(field)},
			$v{typeName}, $v{numeric}, $v{marked > 1});
	}

	/** The same walk the insert's columns take, so the rules and the values line up column for column. */
	static function Rules(row:ClassType, entry:Expr, member:Array<String>, visited:Array<String>,
			rules:Array<Expr>, reads:Array<Expr>):Void {
		for (field in row.fields.get()) {
			if (!field.isPublic || !field.kind.match(FVar(AccNormal | AccNo, _))) {
				continue;
			}
			final name = field.name;
			final read = macro $entry.$name;
			final nested = switch field.type.follow() {
				case TInst(t, _):
					final held = t.get();
					final path = held.pack.concat([held.name]).join(".");
					(path == "String" || path == "Date") ? null : held;
				case _: null;
			}

			if (nested == null) {
				final column = member.concat([ColumnsBuilder.ColumnNameOf(field)]).join(ColumnsBuilder.Separator);
				final type = ColumnsBuilder.SqlTypeOfField(field);
				// The key is the database's to fill in, so what it holds is not the row's to fail.
				final key = member.length == 0 && (name == "id" || field.meta.has("primaryKey"));
				rules.push(macro new codequery.queries.ColumnRule($v{member.concat([name]).join(".")}, $v{column},
					$type, $v{key || IsNullable(field)}));
				reads.push(macro($read : Dynamic));
				continue;
			}

			final path = nested.pack.concat([nested.name]).join(".");
			if (visited.indexOf(path) >= 0) {
				Context.error('${row.name}.$name contains itself, so its columns have no end', entry.pos);
			}
			Rules(nested, read, member.concat([ColumnsBuilder.ColumnNameOf(field)]), visited.concat([path]), rules, reads);
		}
	}

	/** `Null<T>` says so, and so does `@columnNullable(false)` saying the opposite. */
	static function IsNullable(field:ClassField):Bool {
		final stated = switch field.meta.extract("columnNullable") {
			case [{params: [{expr: EConst(CIdent(v))}]}]: v == "true";
			case _: null;
		}
		if (stated != null) {
			return stated;
		}
		return switch field.type {
			case TType(t, _) if (t.get().name == "Null"): true;
			case TAbstract(t, _) if (t.get().name == "Null"): true;
			case TInst(t, _) if (t.get().name == "String"): true;
			case _: false;
		}
	}
	#end
}
