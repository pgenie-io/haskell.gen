let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Project = Deps.Project

let Templates = ../Templates/package.dhall

let Scalar = ./Scalar.dhall

let Input = Project.Value

let Output =
      { sig : Text
      , encoderExp : Text
      , decoderExp : Text
      , testArbitraryGen : Text
      }

let Result = Deps.Lude.Compiled.Type Output

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Deps.Lude.Compiled.flatMap
          Scalar.Output
          Output
          ( \(scalar : Scalar.Output) ->
              Deps.Prelude.Optional.fold
                Project.ArraySettings
                input.arraySettings
                Result
                ( \(arraySettings : Project.ArraySettings) ->
                    let innerElement =
                          if    arraySettings.elementIsNullable
                          then  "(frequency [(1, pure Nothing), (3, Just <\$> ${scalar.testArbitraryGen})])"
                          else  scalar.testArbitraryGen

                    let testArbitraryGen =
                          Natural/fold
                            arraySettings.dimensionality
                            Text
                            ( \(inner : Text) ->
                                "(Data.Vector.fromList <\$> listOf ${inner})"
                            )
                            innerElement

                    in  Deps.Lude.Compiled.ok
                          Output
                          { sig =
                              Templates.DimensionalityType.run
                                { dimensionality = arraySettings.dimensionality
                                , elementIsNullable =
                                    arraySettings.elementIsNullable
                                , elementSig = scalar.sig
                                }
                          , encoderExp =
                              Templates.DimensionalityEncoderExp.run
                                { dimensionality = arraySettings.dimensionality
                                , elementIsNullable =
                                    arraySettings.elementIsNullable
                                , elementExp = scalar.encoderExp
                                }
                          , decoderExp =
                              Templates.DimensionalityDecoderExp.run
                                { dimensionality = arraySettings.dimensionality
                                , elementIsNullable =
                                    arraySettings.elementIsNullable
                                , elementExp = scalar.decoderExp
                                }
                          , testArbitraryGen
                          }
                )
                ( Deps.Lude.Compiled.ok
                    Output
                    { sig = scalar.sig
                    , encoderExp = scalar.encoderExp
                    , decoderExp = scalar.decoderExp
                    , testArbitraryGen = scalar.testArbitraryGen
                    }
                )
          )
          (Scalar.run config input.scalar)

in  Algebra.module Input Output run
