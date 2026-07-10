let Sdk = ../Deps/Sdk.dhall

let Deps = ../Deps/package.dhall

let Params = Text

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
              "\""
          ++  Deps.Prelude.Function.composeList
                Text
                [ Deps.Prelude.Text.replace "\\" "\\\\"
                , Deps.Prelude.Text.replace "\"" "\\\""
                , Deps.Prelude.Text.replace "\n" ("\\n\\" ++ "\n" ++ "\\")
                ]
                params
          ++  "\""
      )
