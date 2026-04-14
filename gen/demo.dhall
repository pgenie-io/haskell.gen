-- Intended to be executed with:
--
-- ```bash
-- dhall to-directory-tree --file src/demo.dhall --output demo-output --allow-path-separators
-- ```
--
-- It however assumes that you have a proper version of Dhall installed.
--
-- The changes required for this to work are in [this PR](https://github.com/dhall-lang/dhall-haskell/pull/2448).
-- You can acquire this version of Dhall by installing from https://github.com/nikita-volkov/dhall-haskell.
let Deps = ./Deps/package.dhall

let Prelude = Deps.Prelude

let Sdk = Deps.Sdk

let Gen = ./Gen.dhall

let project = Sdk.Fixtures.Demo

let config
    : Gen.Config
    = {=}

let compiledFiles = Gen.compile (None Gen.Config) project

let compiledFileMap =
      Sdk.Compiled.map
        Sdk.Files.Type
        (Prelude.Map.Type Text Text)
        Sdk.Files.toFileMap
        compiledFiles

let fileMap = Sdk.Compiled.toFileMap compiledFileMap

in  fileMap : Prelude.Map.Type Text Text
