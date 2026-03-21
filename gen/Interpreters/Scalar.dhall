let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Sdk = Deps.Sdk

let Model = Deps.Sdk.Project

let Primitive = ./Primitive.dhall

let Input = Model.Scalar

let Output = { sig : Text, encoderExp : Text, decoderExp : Text }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Primitive =
              \(primitive : Model.Primitive) ->
                Sdk.Compiled.map
                  Primitive.Output
                  Output
                  ( \(p : Primitive.Output) ->
                      { sig = p.sig
                      , encoderExp = p.encoderExp
                      , decoderExp = p.decoderExp
                      }
                  )
                  (Primitive.run config primitive)
          , Custom =
              \(name : Model.Name) ->
                Sdk.Compiled.ok
                  Output
                  { sig = "Types.${Deps.CodegenKit.Name.toTextInPascal name}"
                  , encoderExp =
                      "IsScalar.encoder @${Deps.CodegenKit.Name.toTextInCamel
                                             name}"
                  , decoderExp =
                      "IsScalar.decoder @${Deps.CodegenKit.Name.toTextInCamel
                                             name}"
                  }
          }
          input

in  Algebra.module Input Output run
