let Params =
      { dimensionality : Natural, elementIsNullable : Bool, elementExp : Text }

let run =
      \(params : Params) ->
        if    Natural/isZero params.dimensionality
        then  params.elementExp
        else  let base =
                    if    params.elementIsNullable
                    then  "Hasql.Decoders.nullable ${params.elementExp}"
                    else  "Hasql.Decoders.nonNullable ${params.elementExp}"

              let base = "Hasql.Decoders.element (${base})"

              let arrayExp =
                    Natural/fold
                      params.dimensionality
                      Text
                      ( \(inner : Text) ->
                          "Hasql.Decoders.dimension Data.Vector.replicateM (${inner})"
                      )
                      base

              in  "Hasql.Decoders.array (${arrayExp})"

in  { Params, run }
