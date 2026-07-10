let Contract = ./Deps/Contract.dhall

let Config = ./Config.dhall

let ResolvedTarget = { rootNamespace : List Text }

let resolve =
      \(config : Optional Config) ->
      \(project : Contract.Project) ->
          { rootNamespace =
            [ project.space.inPascalCase, project.name.inPascalCase ]
          }
        : ResolvedTarget

in  { Type = ResolvedTarget, resolve }
