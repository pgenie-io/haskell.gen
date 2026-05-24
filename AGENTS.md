# Agent Guidance: pgenie Code Generator Architecture

This document describes the architectural blueprint used by this project. It is intentionally language-agnostic so it can be reused for generators targeting any output language.

## Overview

This is a **pure functional code generator** written in Dhall. It transforms a pgenie domain model into a tree of generated source files. The architecture follows a strict **two-phase separation** between *semantic interpretation* and *textual rendering*.

## Core Pattern: Presentation Model + Transform View

The generator is structured as a pipeline:

```
Domain Model  →  Interpreters  →  Presentation Model  →  Templates  →  Source Text
```

- **Interpreters** perform semantic analysis, type mapping, name transformations, and decision-making. They digest the raw domain model and produce a **Presentation Model** — a data structure tailored specifically for rendering.
- **Templates** receive the Presentation Model and emit source text. They contain layout, syntax, and formatting rules for the target language.
- **Algebras** define the abstract contracts (`Interpreter` and `Template`) that enforce this boundary.

This mirrors:
- **Presentation Model / View Model** (Fowler): a self-contained model shaped by the needs of the view.
- **Transform View** (Fowler): data is transformed *before* reaching the template; the template does not query the domain.
- **Intermediate Representation** (compiler architecture): Interpreters lower the domain AST into a target-language-specific IR.
- **Tagless Final** (FP): Algebras define interfaces; concrete files provide interpretations.

## Directory Layout Convention

```
gen/
  Algebras/
    Interpreter.dhall    -- Contract: Config -> Input -> Compiled Output
    Template.dhall       -- Contract: Params -> Text
    package.dhall
  Interpreters/          -- Semantic layer: "what to generate"
    Project.dhall
    Query.dhall
    Value.dhall
    Scalar.dhall
    ...
  Templates/             -- Syntactic layer: "how it looks"
    Module.dhall
    TypesModule.dhall
    ...
  Deps/
    Lude.dhall           -- Standard library: Compiled monad, name utils, file types
    Project.dhall        -- Domain model schema (pgenie SDK)
    Typeclasses.dhall    -- Applicative/Alternative/Traverse for Compiled
  Config.dhall           -- Generator-specific configuration schema
  compile.dhall          -- Entry point: wires interpreters together
  Gen.dhall              -- Public API
```

## Interpreter Naming Constraint

Interpreter modules in `gen/Interpreters/` must be named after the domain model type they consume.

- The **canonical interpreter** for a type uses the exact type name: `Query.dhall` for `Project.Query`, `Member.dhall` for `Project.Member`, `Name.dhall` for `Project.Name`.
- When multiple interpreters consume the same type for different contexts, the name may be **context-qualified**: e.g., `ParamsMember.dhall` for a `Project.Member` interpreter that projects only parameter-related fields.
- **Never** name an interpreter after a target-language concept (e.g., `Rust.dhall`, `Go.dhall`, `Java.dhall`). Target-language specifics belong inside the interpreter body, not in the module name.

This makes the file structure a direct map of the domain model consumption graph and keeps the semantic layer free of presentation concerns.

## Rules for Interpreters

### 1. Own the semantics
Interpreters contain all domain logic:
- Type system mapping (e.g., how domain types map to target-language types)
- Nullability, cardinality, and collection rules
- Name transformations (casing conventions, keyword escaping, sanitization)
- Decisions about derivability, defaults, feature flags
- Filtering and skipping unsupported constructs

### 2. Produce narrow Presentation Models
An Interpreter must not pass raw domain objects to Templates. It must construct a dedicated `Params` record containing **only** the data the Template needs.

### 3. Compose hierarchically
Complex interpreters delegate to simpler ones. Each level handles one concern and passes refined data downward.

Example hierarchy:
```
ProjectInterpreter
  → QueryInterpreter
      → ResultInterpreter
          → MemberInterpreter
              → ValueInterpreter
                  → ScalarInterpreter
```

### 4. Never contain template syntax
Interpreters may construct small text fragments for fields or expressions, but they must not contain module-level layout, import statements, or target-language boilerplate. That belongs in Templates.

## Rules for Templates

### 1. Dumb rendering only
A Template is a pure function `Params -> Text`. It may perform:
- String interpolation
- Conditional layout (`if params.hasX then ... else ...`)
- Looping over pre-sorted, pre-filtered lists

It must **not** perform:
- Domain type mapping
- Name casing transformations
- Nullability or cardinality decisions
- Filtering of unsupported items

### 2. Explicit parameter types
Every Template must declare an explicit `Params` record type. Do not use generic `Map` or domain types as parameters.

### 3. No knowledge of the domain model
A Template should be compilable and understandable without knowing what a `Project.Query` or `Project.Member` is. It only knows its own `Params`.

### 4. One Template per generated artifact
Each Template should correspond to a single kind of output file or syntactic unit (e.g., one module, one config file, one type declaration).

## The Compiled Effect System

Interpreters operate within a monadic/applicative effect system (provided by `Lude.Compiled`). This enables **graceful degradation**: the generator can skip unsupported items while continuing to emit everything else.

### Key operations
- **`ok`** — succeed with a value
- **`report` / `message`** — emit a diagnostic and skip the current item
- **`nest`** — add contextual scope to diagnostics (e.g., "in query X, in parameter Y")
- **`map` / `flatMap` / `traverseList`** — compose interpreters while propagating diagnostics

### Best practices
- Use `nest` at every hierarchical boundary so diagnostics carry full path context.
- Let leaf interpreters (`Primitive`, `Scalar`) report unsupported features.
- Use `Alternative.optional` at aggregation points so a single failure does not collapse the entire generation.
- Never short-circuit the entire compilation for a localized error.

## Data Flow Rules

1. **Unidirectional**: Domain Model → Interpreter → Presentation Model → Template → Text
2. **No callbacks**: Templates must not invoke interpreters. Interpreters must not reach into template internals.
3. **Immutable throughout**: Every layer is a pure function of its inputs.

## Testing Strategy

Because layers communicate only through pure data structures, they can be tested independently:

- **Interpreter unit tests**: Given a domain value, assert the exact shape of the produced Presentation Model.
- **Template unit tests**: Given a hardcoded `Params` record, assert the emitted text matches expected output.
- **Integration tests**: Wire a full domain model through `compile` and assert the resulting file tree.

## Anti-patterns

| Anti-pattern | Why it violates the architecture |
|-------------|----------------------------------|
| Passing `Project.Member` directly into a Template | Templates must not depend on domain types |
| Encoding type-mapping rules inside a Template | Domain logic belongs in Interpreters |
| Constructing import blocks or derive lists in an Interpreter | Syntactic emission belongs in Templates |
| Using `Optional` suppression instead of `Compiled.report` | Hides diagnostics; prevents graceful degradation |
| Making Templates polymorphic over domain types | Breaks the narrow-interface contract |
| Deep nesting of string concatenation in Interpreters | Sign that logic should be split: compute in Interpreter, layout in Template |

## Applying This to a New Target Language

To create a generator for a different target language:

1. **Keep the domain model** (`Project`) unchanged — it is language-agnostic.
2. **Rewrite leaf Interpreters** (`Scalar`, `Primitive`, `Value`) to map domain concepts to the new language's type system.
3. **Rewrite Templates** to emit the new language's syntax.
4. **Keep the architecture**: Algebras, `Compiled` effect system, hierarchical Interpreter composition, and narrow Template interfaces remain identical.


## Design rules

- `gen/Templates/` must not depend on `gen/Interpreters/` or the Project model from `Deps.Sdk`.
- Textual templates should be extracted into `gen/Templates/` as much as possible. `gen/Interpreters/` should primarily be responsible for interpreting the Project model and orchestrating the generation process.
- Templates may depend on other templates and their parameter structures may contain parameter structures of other templates. This may be especially useful for lists and optionals.
  - However a final design decision has not been made on this and it may be simpler to just have the templates be simple and independent, with the interpreters responsible for composing them together as needed by calling them and thus interpreting into structures over chunks of text.
    - Pick either approach, just be consistent within the boundaries of a module.

## Dhall Code Style Rules

### No pointless string concatenations

Never concatenate two string literals with `++` when they can be a single literal. A `"\n"` between two multiline strings, or a short literal like `" */"` after a multiline string, must be absorbed into the adjacent string.

Bad: `'' ... '' ++ " */"` or `someStr ++ "\n" ++ '' ... ''`
Good: fold the literal into the neighbouring multiline string.

### Prefer interpolation over concatenation

When embedding a variable in a string, use Dhall string interpolation (`${expr}`) instead of `"prefix" ++ expr ++ "suffix"`.

Bad: `"Optional<" ++ boxedType ++ ">"`
Good: `"Optional<${boxedType}>"`

### Indent via `indentNonEmpty`, never manually

Lude.Text.indentNonEmpty indents all non-empty lines of a string except the first line.

Never embed indentation in generated string fragments using `${"    "}` padding or hardcoded leading spaces. Instead, produce the string content without indentation and apply `Lude.Text.indentNonEmpty` at the splice site.

Bad (in fragment builder):
```dhall
''
${"        "}/**
${"        "} * Doc.
${"        "} */
${"        "}${fieldType} ${fieldName}''
```

Good (fragment builder produces unindented content, splice site indents):
```dhall
-- builder:
''
/**
 * Doc.
 */
${fieldType} ${fieldName}''

-- splice site:
Lude.Text.indentNonEmpty 8 fragment
```

### Indentation belongs at the splice site, not the construction site

Any string that is meant to be spliced into another string must be constructed without indentation. The `Lude.Text.indentNonEmpty` utility must be applied where the string is spliced into its surrounding context. This eliminates coupling between the string builder and the indentation level of the context it lands in.


## Generated code style rules

- Follow the Ormolu formatting standard (https://github.com/tweag/ormolu) for Haskell code.
