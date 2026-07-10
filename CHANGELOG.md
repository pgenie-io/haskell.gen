# Upcoming

## Non-breaking

- Migrated repository layout to align with the pGenie generator architecture and `java.gen` v1.1.0:
  - Generator implementation moved from `gen/` to `src/`.
  - Public entry point renamed from `gen/Gen.dhall` to `src/package.dhall`.
  - Fixture driver moved from `tests/Exhaustive.dhall` to `demos/Exhaustive.dhall`.
  - Removed stale `gen/compile.dhall`, `gen/Config.dhall`, `gen/InterpreterConfig.dhall`, and the forbidden `gen/Deps/package.dhall` barrel aggregator.
  - Public `Config` and `defaultConfig` are now declared directly in `src/package.dhall`; internal resolved config is derived inside `Interpreters/Project.dhall` and narrowed for child interpreters.

- Updated to the `gen-sdk` v2.0.0 `Sdk.Sigs` API: `Sdk.Sigs.Template.module` became lowercase `Sdk.Sigs.template`; templates now import `Deps/Lude.dhall` and `Deps/Prelude.dhall` directly instead of the removed `Deps/package.dhall` barrel.

# v1.0.0

## Breaking

- Updated `gen-sdk` to v0.11.0 and `lude.dhall` to v5.0.0, migrating to contract v4.0.

# v0.4.0

## Breaking

- Contract updated to v3.0

## Non-breaking

- The generated tests majorly enriched with more test cases and better coverage

# v0.3.0

## Breaking

- Contract updated to v2.0
