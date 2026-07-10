let InterpreterConfig = ../InterpreterConfig.dhall

let Contract = ../Deps/Contract.dhall

let Lude = ../Deps/Lude.dhall

let Sdk = ../Deps/Sdk.dhall

let Value = ./Value.dhall

let Templates = ../Templates/package.dhall

let Input = Contract.Member

let Output =
      { fieldName : Text
      , fieldDeclaration : Text
      , fieldEncoder : Text -> Text
      , fieldDecoder : Text
      , testArbitraryGen : Text
      , identityRectangularDim : Natural
      , identityIsNullable : Bool
      }

let run =
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
        Lude.Compiled.flatMap
          Value.Output
          Output
          ( \(value : Value.Output) ->
              let fieldName = input.name.inCamelCase

              let dimensionality =
                    merge
                      { Some =
                          \(arraySettings : Contract.ArraySettings) ->
                            arraySettings.dimensionality
                      , None = 0
                      }
                      input.value.arraySettings

              let elementIsNullable =
                    merge
                      { Some =
                          \(arraySettings : Contract.ArraySettings) ->
                            arraySettings.elementIsNullable
                      , None = True
                      }
                      input.value.arraySettings

              let sig = value.sig

              let sig = if input.isNullable then "Maybe (${sig})" else sig

              let testArbitraryGen =
                    if    input.isNullable
                    then  "(liftArbitrary ${value.testArbitraryGen})"
                    else  value.testArbitraryGen

              in  Lude.Compiled.ok
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
                    , testArbitraryGen
                    , identityRectangularDim = dimensionality
                    , identityIsNullable = input.isNullable
                    }
          )
          ( Lude.Compiled.nest
              Value.Output
              input.pgName
              (Value.run config input.value)
          )

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
