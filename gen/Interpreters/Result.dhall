let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let ResultRows = ./ResultRows.dhall

let Project = Deps.Project

let Input = Project.Result

let Output = Text -> { typeDecls : Text, decoderExp : Text }

let Result = Deps.Lude.Compiled.Type Output

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Deps.Prelude.Optional.fold
          ResultRows.Input
          input
          Result
          (ResultRows.run config)
          ( Deps.Lude.Compiled.ok
              Output
              ( \(typeNameBase : Text) ->
                  { typeDecls =
                      ''
                      type ${typeNameBase}Result = Int
                      ''
                  , decoderExp = "fromIntegral <\$> Decoders.rowsAffected"
                  }
              )
          )

in  Algebra.module Input Output run
