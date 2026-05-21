let Params =
      { dimensionality : Natural, elementIsNullable : Bool, elementSig : Text }

let run =
      \(params : Params) ->
        if    Natural/isZero params.dimensionality
        then  params.elementSig
        else  let base =
                    if    params.elementIsNullable
                    then  "Maybe (${params.elementSig})"
                    else  params.elementSig

              let arraySig =
                    Natural/fold
                      params.dimensionality
                      Text
                      (\(inner : Text) -> "Vector (${inner})")
                      base

              in  arraySig

in  { Params, run }
