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

Both print the same thing.

## Layout

- `src/Main.hx` — entry point
- `src/model/` — `Delivery` and its enums, ported from C#
- `src/sql/` — the SQL expression tree and the `where()` macro
- `build.hxml` — compiler args for both targets

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
