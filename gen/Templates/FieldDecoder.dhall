let Algebra = ./Algebra/package.dhall

let DimensionalityDecoderExp = ./DimensionalityDecoderExp.dhall

let Params =
      { nullable : Bool, dimensionality : Natural, elementIsNullable : Bool }

in  Algebra.module
      Params
      ( \(params : Params) ->
              ( if    params.nullable
                then  "Hasql.Decoders.nullable"
                else  "Hasql.Decoders.nonNullable"
              )
          ++  " ("
          ++  DimensionalityDecoderExp.run
                { dimensionality = params.dimensionality
                , elementIsNullable = params.elementIsNullable
                , elementExp = "Hasql.Mapping.IsScalar.decoder"
                }
          ++  ")"
      )
