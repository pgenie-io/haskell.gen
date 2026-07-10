let Deps = ../Deps/package.dhall

let ResolvedTarget = ../ResolvedTarget.dhall

let ResultRows = ./ResultRows.dhall

let Contract = Deps.Contract

let Input = Contract.Result

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
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
        merge
          { Void = voidResult
          , RowsAffected = rowsAffectedResult
          , Rows = ResultRows.run config
          }
          input

in  Deps.Sdk.Sigs.Interpreter.module ResolvedTarget.Type Input Output run
