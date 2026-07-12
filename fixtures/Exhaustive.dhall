-- Intended to be executed with:
--
-- ```bash
-- dhall to-directory-tree --file demos/Exhaustive.dhall --output demo-verify --allow-path-separators
-- ```
--
-- This generates the demo output for the music_catalogue fixture project.
let Sdk = ../src/Deps/Sdk.dhall

let Gen = ../src/package.dhall

let project = Sdk.Fixtures.Exhaustive

let compiledFiles = Sdk.Output.toFileMap (Gen.compile (None Gen.Config) project)

in  compiledFiles
