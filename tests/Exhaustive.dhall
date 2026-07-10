-- Intended to be executed with:
--
-- ```bash
-- dhall to-directory-tree --file tests/Exhaustive.dhall --output demo-output --allow-path-separators
-- ```
--
-- This generates the demo output for the music_catalogue fixture project.
let Sdk = ../gen/Deps/Sdk.dhall

let Gen = ../gen/Gen.dhall

let project = Sdk.Fixtures.Exhaustive

let compiledFiles = Sdk.Output.toFileMap (Gen.compile (None Gen.Config) project)

in  compiledFiles
