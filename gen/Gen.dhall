let Sdk = ./Deps/Sdk.dhall

let ProjectInterpreter = ./Interpreters/Project.dhall

let Config = ProjectInterpreter.Config

let defaultConfig = {=}

in  Sdk.Sigs.generator Config defaultConfig ProjectInterpreter.run
