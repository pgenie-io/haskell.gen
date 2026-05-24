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

                    let rectangularArbitrary =
                          let generated =
                                Natural/fold
                                  arraySettings.dimensionality
                                  { nextIndex : Natural
                                  , bindings : Text
                                  , exp : Text
                                  }
                                  ( \ ( acc
                                      : { nextIndex : Natural
                                        , bindings : Text
                                        , exp : Text
                                        }
                                      ) ->
                                      let dimText = Natural/show acc.nextIndex

                                      let binding =
                                            if    Natural/isZero
                                                    ( Natural/subtract
                                                        acc.nextIndex
                                                        arraySettings.dimensionality
                                                    )
                                            then  "len${dimText} <- chooseInt (0, bound)"
                                            else  "len${dimText} <- chooseInt (1, positiveBound)"

                                      in  { nextIndex = acc.nextIndex + 1
                                          , bindings =
                                              acc.bindings ++ binding ++ "; "
                                          , exp =
                                              "(Data.Vector.fromList <\$> vectorOf len${dimText} ${acc.exp})"
                                          }
                                  )
                                  { nextIndex = 1
                                  , bindings = ""
                                  , exp = innerElement
                                  }

                          in  "(sized (\\size -> do { let { bound = max 0 (min 4 size); positiveBound = max 1 bound }; ${generated.bindings}${generated.exp} }))"

                    let testArbitraryGen = rectangularArbitrary

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
