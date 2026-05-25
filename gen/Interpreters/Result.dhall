let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let ResultRows = ./ResultRows.dhall

let Project = Deps.Project

let Input = Project.Result

let Output = Text -> { typeDecls : Text, decoderExp : Text }

let Result = Deps.Lude.Compiled.Type Output

let rowsAffectedResult
    : Result
    = Deps.Lude.Compiled.ok
        Output
        ( \(typeNameBase : Text) ->
            { typeDecls =
                ''
                type ${typeNameBase}Result = Int
                ''
            , decoderExp = "fromIntegral <\$> Hasql.Decoders.rowsAffected"
            }
        )

let voidResult
    : Result
    = Deps.Lude.Compiled.ok
        Output
        ( \(typeNameBase : Text) ->
            { typeDecls =
                ''
                type ${typeNameBase}Result = ()
                ''
            , decoderExp = "Hasql.Decoders.noResult"
            }
        )

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Void = voidResult
          , RowsAffected = rowsAffectedResult
          , Rows = ResultRows.run config
          }
          input

in  Algebra.module Input Output run
