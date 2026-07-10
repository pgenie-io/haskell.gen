let Deps = ../Deps/package.dhall

let ResolvedTarget = ../ResolvedTarget.dhall

let Contract = Deps.Contract

let Primitive = ./Primitive.dhall

let Input = Contract.Scalar

let Output =
      { sig : Text
      , encoderExp : Text
      , decoderExp : Text
      , testArbitraryGen : Text
      }

let run =
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
        merge
          { Primitive =
              \(primitive : Contract.Primitive) ->
                Deps.Lude.Compiled.map
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
                Deps.Lude.Compiled.ok
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

in  Deps.Sdk.Sigs.Interpreter.module ResolvedTarget.Type Input Output run
