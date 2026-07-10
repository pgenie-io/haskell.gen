let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Params = Text

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
              "\""
          ++  Prelude.Function.composeList
                Text
                [ Prelude.Text.replace "\\" "\\\\"
                , Prelude.Text.replace "\"" "\\\""
                , Prelude.Text.replace "\n" ("\\n\\" ++ "\n" ++ "\\")
                ]
                params
          ++  "\""
      )
