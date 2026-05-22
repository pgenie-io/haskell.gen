let Deps = ../../Deps/package.dhall

let CustomTypeDefault = { typeName : Text, literal : Text }

let Config =
      { rootNamespace : List Text, customTypeDefaults : List CustomTypeDefault }

let module =
      \(Input : Type) ->
      \(Output : Type) ->
        let Result = Deps.Lude.Compiled.Type Output

        let Run = Config -> Input -> Result

        in  \(run : Run) -> { Input, Output, Result, Run, run }

in  { Config, module }
