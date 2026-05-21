let Deps = ../../Deps/package.dhall

let Config = { rootNamespace : List Text }

let module =
      \(Input : Type) ->
      \(Output : Type) ->
        let Result = Deps.Lude.Compiled.Type Output

        let Run = Config -> Input -> Result

        in  \(run : Run) -> { Input, Output, Result, Run, run }

in  { Config, module }
