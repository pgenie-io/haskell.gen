let Project = ./Deps/Project.dhall

let Config = ./Config.dhall

let ProjectInterpreter = ./Interpreters/Project.dhall

in  \(config : Optional Config) ->
    \(project : Project.Project) ->
      let interpreterConfig =
            { rootNamespace =
              [ project.space.inPascalCase, project.name.inPascalCase ]
            }

      in  ProjectInterpreter.run interpreterConfig project
