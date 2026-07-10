let InterpreterConfig = ../InterpreterConfig.dhall

let ResultRows = ./ResultRows.dhall

let Contract = ../Deps/Contract.dhall

let Lude = ../Deps/Lude.dhall

let Sdk = ../Deps/Sdk.dhall

let Input = Contract.Result

let Output = Text -> { typeDecls : Text, decoderExp : Text }

let Result = Lude.Compiled.Type Output

let rowsAffectedResult
    : Result
    = Lude.Compiled.ok
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
    = Lude.Compiled.ok
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
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
        merge
          { Void = voidResult
          , RowsAffected = rowsAffectedResult
          , Rows = ResultRows.run config
          }
          input

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
