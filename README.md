# haxeMacros

A Haxe playground targeting the **eval** target (Haxe's built-in interpreter) —
the target macros run on, so no external runtime is needed.

## Setup

```sh
brew install haxe
```

Homebrew's caveat suggests adding this to your shell profile (not required for the
`haxe` binary itself, but useful for tools that shell out to the compiler):

```sh
export HAXE_STD_PATH="/opt/homebrew/lib/haxe/std"
```

Verify: `haxe --version` (this project was set up with 4.3.7).

PHP is pinned in `.tool-versions` (asdf) and is needed for the second build
target. Haxe 4's PHP target emits **PHP 7.0+** code — PHP 5 support was dropped
in Haxe 4, so there is no `-D php7` to opt into any more; `--php` *is* the PHP 7
target. That output runs unchanged on the 8.x interpreter pinned here.

## Run

```sh
haxe build.hxml
```

This builds twice from the same source:

1. **eval** — Haxe's built-in interpreter. `--interp` compiles and runs in one
   step, so there is no artifact.
2. **PHP** — generated into `bin/php/`, then run via `--cmd php bin/php/index.php`.

Both render the same statements. The PHP one also runs them: `SampleDbInitializer`
builds `SampleDb` over the MySQL driver, and on PHP the driver connects through
PDO (`pdo_mysql`), scaffolds a migration into `Migrations/` if the entities have
drifted from the last snapshot, applies what is pending, and executes the sample.
Every other target has no MySQL client, so there the configuration renders only.

The sample expects MySQL at `127.0.0.1:3306`, database `codequery_sample`, user
`docker`/`docker`:

```sh
docker run -d --name codequery-sample-mysql \
  -e MYSQL_ROOT_PASSWORD=docker -e MYSQL_DATABASE=codequery_sample \
  -e MYSQL_USER=docker -e MYSQL_PASSWORD=docker -p 3306:3306 \
  mysql:8.0 --default-authentication-plugin=mysql_native_password
```

(`mysql_native_password` because this PHP's `mysqlnd` cannot answer MySQL 8's
default `caching_sha2_password`.)

## Layout

- `src/Main.hx` — entry point
- `src/model/` — `Delivery` and its enums, ported from C#
- `src/sql/` — the SQL expression tree and the `where()` macro
- `build.hxml` — compiler args for both targets

## What a query clause compiles to

A clause written as a lambda over the entity — `Where(b -> b.price.zar > 100)`,
`Select(b -> {price: b.price.zar, id: b.id})` — is converted while compiling, but
it stays a function in the output: a callback over the row's *columns*, each an
expression. The generated PHP reads as the chain that was written:

```php
$rows = Main::$db->Bookings
	->From()
	->Where(function ($b) {
		return Expr::greaterThan($b->price->zar, Expr::constInt(100));
	})
	->Select(function ($b) {
		return new HxAnon(["price" => $b->price->zar, "id" => $b->id]);
	})
	->Fetch();
```

`$b` is a `BookingColumns`, generated per entity by `ColumnsBuilder`: one member per
column, an object flattened into the row (`price.zar`) a columns object of its own.
The query calls the callback with the columns of each row it is over, and
`RowProjection` flattens what a `select` answers with — a structure, a whole row,
one expression — into the statement's selection. A structure's members come back
in the order they were written; on the eval target, which orders an object's
fields by name, the order is written on the structure (`RowProjection.Ordered`).

`Fetch()` reads the rows back as the row type: entities for a query over a table
(`BookingColumns.Read` rebuilds one, flattened objects included), the structure a
projection built with each value as its column's type, the one value a lone
expression selects. A query over several rows, not yet projected, answers as the
driver sent it.

A table has to know its row's shape to hand a lambda its columns: `DbTable.of()`,
`Query.table(T)` and `DbView.of(…)` give it one; a `new DbTable<T>(…)` written by
hand has none, and a lambda over it says so.

## `Query.where` — lambda to SQL, at compile time

The C# equivalent of this is:

```csharp
string Where(Expression<Func<Delivery, bool>> predicate) { ... }
```

C# reifies the lambda into an `Expression` tree at *runtime* and walks it there.
A Haxe macro receives the syntax tree at *compile time* instead, so the analysis
happens during compilation:

```haxe
Query.where(d -> d.id > 10)   // ==> "d.Id > 10"
```

The macro walks the Haxe `Expr`, builds a tree of `SqlExpression` nodes, and
renders it:

```
BinaryExpression
  operator: >
  left:  ColumnExpression(d.Id)
  right: ConstIntExpression(10)
```

Because all of that runs during compilation, the call site is left holding only
the finished string — the AST classes never reach the generated output.

### Supported so far

- Columns — fields of the lambda parameter, mapped to PascalCase (`d.id` -> `d.Id`)
- Constants — `Int`, `String`, `Bool`
- Binary operators — `== != > >= < <=` and `&& ||`

### Editor support inside the lambda

A macro receives its argument as *syntax*, and Haxe answers completion, hover
and go-to-definition while **typing** an expression. A macro that only reads the
syntax tree and returns a string therefore never types its argument, and an
editor has nothing to offer inside the lambda — no completion after `d.`, no
jump to the field, no hover. `ExprOf<T>` does not change this; it documents the
expected type, it does not cause typing.

So `where()` types the predicate against `Delivery -> Bool` and discards the
result:

```haxe
final entity = Context.toComplexType(Context.getType(ENTITY));
final signature = ComplexType.TFunction([entity], macro :Bool);
Context.typeExpr(macro @:pos(predicate.pos) ($predicate : $signature));
```

The typed expression is thrown away, so the generated code is byte for byte what
it was without it — but the editor now has a typed tree to answer questions
against, and the body is type-checked for free.

### Compile errors, not runtime surprises

Field names are checked against the real `Delivery` type, and the error points
at the offending part of the predicate:

```
Main.hx:3: characters 38-48 : model.Delivery has no field noteNumber
Main.hx:3: characters 36-49 : Cannot compare String and Int
Main.hx:3: characters 36-44 : Operator + has no SQL equivalent
```

The first two come from typing the predicate, the third from the translation
itself.
