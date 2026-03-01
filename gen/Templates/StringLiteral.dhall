let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params = Text

in  Algebra.module
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
