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

### Compile errors, not runtime surprises

Field names are checked against the real `Delivery` type, and the error points
at the offending part of the predicate:

```
Main.hx:3: characters 36-48 : Delivery has no field "noteNumber"
Main.hx:3: characters 36-44 : Operator + has no SQL equivalent
```
