let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params = Optional Text

in  Algebra.module
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
