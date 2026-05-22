let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Project = Deps.Project

let Value = ./Value.dhall

let Templates = ../Templates/package.dhall

let Input = Project.Member

let Output =
      { fieldName : Text
      , fieldDeclaration : Text
      , fieldEncoder : Text -> Text
      , fieldDecoder : Text
      , testDefaultLiteral : Text
      }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Deps.Lude.Compiled.flatMap
          Value.Output
          Output
          ( \(value : Value.Output) ->
              let fieldName = input.name.inCamelCase

              let dimensionality =
                    merge
                      { Some =
                          \(arraySettings : Project.ArraySettings) ->
                            arraySettings.dimensionality
                      , None = 0
                      }
                      input.value.arraySettings

              let elementIsNullable =
                    merge
                      { Some =
                          \(arraySettings : Project.ArraySettings) ->
                            arraySettings.elementIsNullable
                      , None = True
                      }
                      input.value.arraySettings

              let sig = value.sig

              let sig = if input.isNullable then "Maybe (${sig})" else sig

              let testDefaultLiteral =
                    if    input.isNullable
                    then  "Nothing"
                    else  value.testDefaultLiteral

              in  Deps.Lude.Compiled.ok
                    Output
                    { fieldName
                    , fieldEncoder =
                        \(surroundingEncoder : Text) ->
                          Templates.FieldEncoder.run
                            { name = fieldName
                            , nullable = input.isNullable
                            , dimensionality
                            , elementIsNullable
                            , surroundingEncoder
                            }
                    , fieldDecoder =
                        Templates.FieldDecoder.run
                          { nullable = input.isNullable
                          , dimensionality
                          , elementIsNullable
                          }
                    , fieldDeclaration =
                        Templates.FieldDeclaration.run
                          { name = fieldName
                          , sig
                          , docs = Some "Maps to @${input.pgName}@."
                          }
                    , testDefaultLiteral
                    }
          )
          ( Deps.Lude.Compiled.nest
              Value.Output
              input.pgName
              (Value.run config input.value)
          )

in  Algebra.module Input Output run
