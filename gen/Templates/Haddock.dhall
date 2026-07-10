let Sdk = ../Deps/Sdk.dhall

let Deps = ../Deps/package.dhall

let Params = Optional Text

in  Sdk.Sigs.Template.module
      Params
      ( \(params : Params) ->
          merge
            { None = ""
            , Some =
                \(text : Text) ->
                  "-- | " ++ Deps.Lude.Text.prefixEachLine "-- " text ++ "\n"
            }
            params
      )
