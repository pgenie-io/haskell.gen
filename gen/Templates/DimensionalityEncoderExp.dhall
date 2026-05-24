let Params =
      { dimensionality : Natural, elementIsNullable : Bool, elementExp : Text }

let run =
      \(params : Params) ->
        if    Natural/isZero params.dimensionality
        then  params.elementExp
        else  let base =
                    if    params.elementIsNullable
                    then  "Hasql.Encoders.nullable ${params.elementExp}"
                    else  "Hasql.Encoders.nonNullable ${params.elementExp}"

              let base = "Hasql.Encoders.element (${base})"

              let arrayExp =
                    Natural/fold
                      params.dimensionality
                      Text
                      ( \(inner : Text) ->
                          "Hasql.Encoders.dimension Data.Vector.foldl' (${inner})"
                      )
                      base

              in  "Hasql.Encoders.array (${arrayExp})"

in  { Params, run }
