# Agent Guidance: pgenie Haskell Generator

This project is a pGenie generator that compiles a pGenie project (SQL migrations and queries) into a Haskell library, its Cabal manifest, tests, and documentation.

It follows the [pGenie generator architecture](../gen-sdk/docs/generator-architecture.md). The reference implementation is [java.gen](https://github.com/pgenie-io/java.gen).

## Repository layout

```
src/
  package.dhall        -- entry point: Config, Config/default, Sdk.Sigs.generator
  Deps/                -- pinned remote imports ONLY (one file per dependency)
    Contract.dhall     -- gen-contract (Project model + Output/Report/File types)
    Sdk.dhall          -- gen-sdk (Sigs, Fixtures, Output.toFileMap)
    Prelude.dhall      -- Dhall Prelude
    Lude.dhall         -- lude.dhall (Compiled, File, Text utilities)
    Typeclasses.dhall  -- typeclasses.dhall (Applicative, Alternative, ...)
  Interpreters/        -- model → data, tree-shaped, rooted at Project.dhall
  Templates/           -- pure Params → Text rendering functions
demos/                 -- executable fixture drivers, e.g. Exhaustive.dhall
```

`Deps/` contains nothing but frozen (`sha256`-pinned) remote imports. There is no `Deps/package.dhall` barrel: every consumer imports exactly the `Deps/*.dhall` files it uses.

## The three sigs

Every module in `Interpreters/` ends with `Sdk.Sigs.interpreter Config Input Output run`, declaring its `Config` locally. Every module in `Templates/` ends with `Sdk.Sigs.template Params run`. The entry point in `src/package.dhall` calls `Sdk.Sigs.generator Config Config/default ProjectInterpreter.run`.

Use the lowercase constructors directly — there is no `.module` field:

```dhall
Sdk.Sigs.interpreter   -- not Sdk.Sigs.Interpreter.module
Sdk.Sigs.template      -- not Sdk.Sigs.Template.module
Sdk.Sigs.generator     -- top-level entry constructor
```

## Interpreters

Interpreters translate the `gen-contract` model into Haskell-specific data. Rules:

- The tree mirrors the model: `Project` → `Query`/`CustomType` → `Result`/`Member`/`QueryFragments` → `Value` → `Scalar` → `Primitive`.
- `Output` is plain data (`Text`, `Bool`, `List`, records) — never a function.
- Render as early as possible: an interpreter evaluates templates and puts the resulting `Text` in its output.
- Wrap each addressable unit in `Lude.Compiled.nest label` so reports carry their path.
- Cross-file aggregation (cabal file, re-export modules, README) happens in `Interpreters/Project`.

`Interpreters/Project.dhall` receives the public `Config` (currently `{}`), derives any project-specific values from the `Project` model, and passes narrower records down to children.

## Templates

Templates are pure `Params -> Text` functions. They are blind to the model and do not import `Deps/Contract.dhall` or `Deps/Sdk.dhall`. They may import `Deps/Lude.dhall` and `Deps/Prelude.dhall` for text/list utilities. Templates do not call other templates; composition happens in interpreters.

## Testing and verification

`demos/Exhaustive.dhall` applies the generator to `Sdk.Fixtures.Exhaustive` and produces a file map via `Sdk.Output.toFileMap`:

```dhall
let Sdk = ../src/Deps/Sdk.dhall
let Gen = ../src/package.dhall
in  Sdk.Output.toFileMap (Gen.compile (None Gen.Config) Sdk.Fixtures.Exhaustive)
```

Materialise locally with:

```bash
dhall to-directory-tree --allow-path-separators --file demos/Exhaustive.dhall --output demo-verify
```

Then build and test the generated project:

```bash
cabal test --project-dir=./demo-verify all
```

The materialised `demo-verify/` directory is not committed.

## Dhall style

- Prefer interpolation over concatenation: `"Optional<${t}>"`.
- Apply `Lude.Text.indent` / `Lude.Text.prefixEachLine` at the splice site, not inside the fragment.
- Keep `Config` declarations local to each interpreter module.
- Format with `dhall format --transitive`; keep everything type-checkable with `dhall type`.
