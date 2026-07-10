let Contract = ./Deps/Contract.dhall

let Config = ./Config.dhall

let ResolvedTarget = ./ResolvedTarget.dhall

let ProjectInterpreter = ./Interpreters/Project.dhall

in  \(config : Optional Config) ->
    \(project : Contract.Project) ->
      ProjectInterpreter.run (ResolvedTarget.resolve config project) project
