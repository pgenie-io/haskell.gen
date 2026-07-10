let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Params = Optional Text

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          merge
            { None = ""
            , Some =
                \(text : Text) ->
                  "-- | " ++ Lude.Text.prefixEachLine "-- " text ++ "\n"
            }
            params
      )
