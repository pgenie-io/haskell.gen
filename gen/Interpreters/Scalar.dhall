let InterpreterConfig = ../InterpreterConfig.dhall

let Contract = ../Deps/Contract.dhall

let Lude = ../Deps/Lude.dhall

let Sdk = ../Deps/Sdk.dhall

let Primitive = ./Primitive.dhall

let Input = Contract.Scalar

let Output =
      { sig : Text
      , encoderExp : Text
      , decoderExp : Text
      , testArbitraryGen : Text
      }

let run =
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
        merge
          { Primitive =
              \(primitive : Contract.Primitive) ->
                Lude.Compiled.map
                  Primitive.Output
                  Output
                  ( \(p : Primitive.Output) ->
                      { sig = p.sig
                      , encoderExp = p.encoderExp
                      , decoderExp = p.decoderExp
                      , testArbitraryGen = p.testArbitraryGen
                      }
                  )
                  (Primitive.run config primitive)
          , Custom =
              \(name : Contract.Name) ->
                Lude.Compiled.ok
                  Output
                  { sig = name.inPascalCase
                  , encoderExp =
                      "Hasql.Mapping.IsScalar.encoder @${name.inCamelCase}"
                  , decoderExp =
                      "Hasql.Mapping.IsScalar.decoder @${name.inCamelCase}"
                  , testArbitraryGen = "arbitrary"
                  }
          }
          input

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
