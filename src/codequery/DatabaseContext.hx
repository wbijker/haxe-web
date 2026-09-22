package codequery;

import codequery.migrations.DatabaseTableDefinition;
import codequery.queries.IDeleteQuery;
import codequery.queries.ISelectQuery;
import codequery.queries.IUpdateQuery;
import codequery.sqldrivers.ISqlTranslator;
import codequery.sqlexpressions.ISqlStatement;
import codequery.sqlexpressions.SchemaChangeExpression;
#if macro
import codequery.migrations.SchemaMembers;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Every table definition of a schema, and query access to them, over one driver.
	`Register(User, "Users")` is C#'s `Register<User>("Users")`.
**/
class DatabaseContext {
	public final Driver:ISqlTranslator;

	final tables = new Map<String, DatabaseTableDefinition>();
	final tableNames = new Map<String, String>();
	final order:Array<String> = [];

	public function new(driver:ISqlTranslator) {
		if (driver == null) {
			throw "A context needs a driver";
		}
		this.Driver = driver;
	}

	/** Every registered table definition. */
	public var Tables(get, never):Array<DatabaseTableDefinition>;

	function get_Tables():Array<DatabaseTableDefinition> {
		return [for (entity in order) tables.get(entity)];
	}

	/**
		Registers an entity's table: by definition, `Register(User, definition)`; by name,
		`Register(User, "Users")`; or by the entity's own name, `Register(User)`.
	**/
	public macro function Register(self:Expr, entity:Expr, ?with:Expr):Expr {
		final row = SchemaMembers.ClassTypeOf(entity);
		final path = SchemaMembers.PathOf(row);
		if (with == null || with.expr.match(EConst(CIdent("null")))) {
			return macro $self.RegisterNamed($v{path}, $v{row.name});
		}
		return switch with.expr {
			case EConst(CString(_)): macro $self.RegisterNamed($v{path}, $with);
			case _: macro $self.RegisterDefinition($v{path}, $with);
		}
	}

	public function RegisterDefinition(entity:String, definition:DatabaseTableDefinition):DatabaseContext {
		if (!tables.exists(entity)) {
			order.push(entity);
		}
		tables.set(entity, definition);
		tableNames.set(entity, definition.TableName);
		return this;
	}

	public function RegisterNamed(entity:String, tableName:String):DatabaseContext {
		return RegisterDefinition(entity, new DatabaseTableDefinition(tableName));
	}

	public macro function GetTableDefinition(self:Expr, entity:Expr):Expr {
		return macro $self.DefinitionOf($v{SchemaMembers.ClassPathOf(entity)}, $v{SchemaMembers.ClassNameOf(entity)});
	}

	public function DefinitionOf(entity:String, name:String):DatabaseTableDefinition {
		final definition = tables.get(entity);
		if (definition == null) {
			throw 'Entity type $name is not registered.';
		}
		return definition;
	}

	public macro function GetTableName(self:Expr, entity:Expr):Expr {
		return macro $self.TableNameOf($v{SchemaMembers.ClassPathOf(entity)}, $v{SchemaMembers.ClassNameOf(entity)});
	}

	public function TableNameOf(entity:String, name:String):String {
		final tableName = tableNames.get(entity);
		if (tableName == null) {
			throw 'Entity type $name is not registered.';
		}
		return tableName;
	}

	/** A query over an entity's registered table. */
	public macro function Query(self:Expr, entity:Expr):Expr {
		final type = haxe.macro.TypeTools.toComplexType(SchemaMembers.TypeOf(entity));
		final path = SchemaMembers.ClassPathOf(entity);
		final name = SchemaMembers.ClassNameOf(entity);
		final shape = codequery.sqlexpressions.ExpressionConverter.ShapeOf(SchemaMembers.TypeOf(entity));
		return macro new codequery.DbTable<$type>(new codequery.QualifiedTableName($self.TableNameOf($v{path}, $v{name})), $v{path},
			null, null, $shape);
	}

	public macro function From(self:Expr, entity:Expr):Expr {
		return macro $self.Query($entity).From();
	}

	public macro function Update(self:Expr, entity:Expr):Expr {
		return macro $self.Query($entity).Update();
	}

	public macro function Delete(self:Expr, entity:Expr):Expr {
		return macro $self.Query($entity).Delete();
	}

	/** A statement as SQL, in the driver's dialect. */
	public function ToSql(statement:ISqlStatement):String {
		return Driver.ToSql(statement);
	}

	public macro function GetCreateTableSql(self:Expr, entity:Expr, ?ifNotExists:Expr):Expr {
		final wanted = ifNotExists == null ? macro false : ifNotExists;
		return macro $self.CreateTableSqlOf($v{SchemaMembers.ClassPathOf(entity)}, $v{SchemaMembers.ClassNameOf(entity)}, $wanted);
	}

	public function CreateTableSqlOf(entity:String, name:String, ifNotExists:Bool = false):String {
		return Driver.ToSql(DefinitionOf(entity, name).ToTableCreateExpression(ifNotExists));
	}

	public function GetCreateAllTablesSql(ifNotExists:Bool = false):Array<String> {
		return Tables.map(definition -> Driver.ToSql(definition.ToTableCreateExpression(ifNotExists)));
	}

	/** The changes that turn `other`'s schema into this one's. */
	public function Diff(other:DatabaseContext):Array<SchemaChangeExpression> {
		var changes:Array<SchemaChangeExpression> = [];

		for (entity in order) {
			if (other.tables.exists(entity)) {
				continue;
			}
			final definition = tables.get(entity);
			changes.push(definition.ToCreateTableExpression());
			for (index in definition.Indexes) {
				changes.push(index.ToCreateIndexExpression(definition.TableName, definition.Schema));
			}
		}

		for (entity in other.order) {
			if (!tables.exists(entity)) {
				final definition = other.tables.get(entity);
				changes.push(new DropTableExpression(definition.TableName, definition.Schema));
			}
		}

		for (entity in order) {
			if (other.tables.exists(entity)) {
				changes = changes.concat(tables.get(entity).Diff(other.tables.get(entity)));
			}
		}

		return changes;
	}

	/** The same tables over another driver. */
	public function WithDriver(driver:ISqlTranslator):DatabaseContext {
		final context = new DatabaseContext(driver);
		for (entity in order) {
			context.RegisterDefinition(entity, tables.get(entity));
		}
		return context;
	}
}
