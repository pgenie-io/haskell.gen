-- Intended to be executed with:
--
-- ```bash
-- dhall to-directory-tree --file tests/AllTypes.dhall --output demo-output --allow-path-separators
-- ```
--
-- This generates the demo output for the music_catalogue fixture project.
let Sdk = ../gen/Deps/GenSdk.dhall

let Gen = ../gen/Gen.dhall

let project = Sdk.Fixtures.AllTypes

let compiledFiles = Gen.compileToFileMap (None Gen.Config) project

in  compiledFiles
