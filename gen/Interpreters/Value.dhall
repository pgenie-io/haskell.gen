let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Lude = Deps.Lude

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
                                  , bindings : List Text
                                  , exp : Text
                                  }
                                  ( \ ( acc
                                      : { nextIndex : Natural
                                        , bindings : List Text
                                        , exp : Text
                                        }
                                      ) ->
                                      let dimText = Natural/show acc.nextIndex

                                      let boundExp =
                                            if    Natural/isZero
                                                    ( Natural/subtract
                                                        acc.nextIndex
                                                        arraySettings.dimensionality
                                                    )
                                            then  "(0, max 0 (min 4 size))"
                                            else  "(1, max 1 (max 0 (min 4 size)))"

                                      let binding =
                                            "len${dimText} <- chooseInt ${boundExp}"

                                      in  { nextIndex = acc.nextIndex + 1
                                          , bindings =
                                              acc.bindings # [ binding ]
                                          , exp =
                                              "(Data.Vector.fromList <\$> vectorOf len${dimText} ${acc.exp})"
                                          }
                                  )
                                  { nextIndex = 1
                                  , bindings = [] : List Text
                                  , exp = innerElement
                                  }

                          let statements =
                                Deps.Prelude.Text.concatSep
                                  "\n"
                                  generated.bindings

                          in  ''
                              ( sized \size -> do
                                  ${Lude.Text.indentNonEmpty 4 statements}
                                  ${Lude.Text.indentNonEmpty 4 generated.exp}
                              )''

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
