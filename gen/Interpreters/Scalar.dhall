let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Project = Deps.Project

let Primitive = ./Primitive.dhall

let Input = Project.Scalar

let CustomTypeDefault = { typeName : Text, literal : Text }

let Output =
      { sig : Text
      , encoderExp : Text
      , decoderExp : Text
      , testDefaultLiteral : Text
      }

let lookupCustomDefaultLiteral =
      \(customTypeDefaults : List CustomTypeDefault) ->
      \(typeName : Text) ->
        let matchingDefaults =
              Deps.Prelude.List.filter
                CustomTypeDefault
                (\(d : CustomTypeDefault) -> Text/equal d.typeName typeName)
                customTypeDefaults

        in  Deps.Prelude.Optional.fold
              CustomTypeDefault
              (Deps.Prelude.List.head CustomTypeDefault matchingDefaults)
              Text
              (\(d : CustomTypeDefault) -> d.literal)
              "(error \"No default value for custom types\")"

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
                      lookupCustomDefaultLiteral
                        config.customTypeDefaults
                        name.inPascalCase
                  }
          }
          input

in  Algebra.module Input Output run
