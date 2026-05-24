let Algebra = ./Algebra/package.dhall

let DimensionalityEncoderExp = ./DimensionalityEncoderExp.dhall

let Params =
      { name : Text
      , nullable : Bool
      , dimensionality : Natural
      , elementIsNullable : Bool
      , surroundingEncoder : Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
              "(."
          ++  params.name
          ++  ") >\$< "
          ++  params.surroundingEncoder
          ++  " ("
          ++  ( if    params.nullable
                then  "Hasql.Encoders.nullable"
                else  "Hasql.Encoders.nonNullable"
              )
          ++  " ("
          ++  DimensionalityEncoderExp.run
                { dimensionality = params.dimensionality
                , elementIsNullable = params.elementIsNullable
                , elementExp = "Hasql.Mapping.IsScalar.encoder"
                }
          ++  "))"
      )
