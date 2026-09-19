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

## Run

```sh
haxe build.hxml
```

Expected output:

```
src/Main.hx:3: Hello, World!
Hello from the Haxe eval target!
```

`--interp` both compiles and runs in one step, so there is no build artifact.

## Layout

- `src/Main.hx` — entry point
- `build.hxml` — compiler args for the eval target
