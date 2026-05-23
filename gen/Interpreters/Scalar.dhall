let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Project = Deps.Project

let Primitive = ./Primitive.dhall

let Input = Project.Scalar

let Output =
      { sig : Text
      , encoderExp : Text
      , decoderExp : Text
      , testDefaultLiteral : Text
      }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Primitive =
              \(primitive : Project.Primitive) ->
                Deps.Lude.Compiled.map
                  Primitive.Output
                  Output
                  ( \(p : Primitive.Output) ->
                      { sig = p.sig
                      , encoderExp = p.encoderExp
                      , decoderExp = p.decoderExp
                      , testDefaultLiteral = p.testDefaultLiteral
                      }
                  )
                  (Primitive.run config primitive)
          , Custom =
              \(name : Project.Name) ->
                Deps.Lude.Compiled.ok
                  Output
                  { sig = "Types.${name.inPascalCase}"
                  , encoderExp = "IsScalar.encoder @${name.inCamelCase}"
                  , decoderExp = "IsScalar.decoder @${name.inCamelCase}"
                  , testDefaultLiteral =
                      "(error \"No test default for ${name.inPascalCase}\")"
                  }
          }
          input

in  Algebra.module Input Output run
