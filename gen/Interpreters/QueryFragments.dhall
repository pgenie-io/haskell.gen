let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Prelude = Deps.Prelude

let Project = Deps.Project

let Input = Project.QueryFragments

let Output
    : Type
    = { exp : Text, haddock : Text }

let escapeText
    : Text -> Text
    = Prelude.Function.composeList
        Text
        [ Prelude.Text.replace "\\" "\\\\"
        , Prelude.Text.replace "\"" "\\\""
        , Prelude.Text.replace "\n" ("\\n\\" ++ "\n" ++ "\\")
        ]

let renderExp
    : Project.QueryFragments -> Text
    = \(fragments : Project.QueryFragments) ->
            "\""
        ++  Prelude.Text.concatMap
              Project.QueryFragment
              ( \(queryFragment : Project.QueryFragment) ->
                  merge
                    { Sql = escapeText
                    , Var =
                        \(var : Project.Var) ->
                          "\$" ++ Deps.Prelude.Natural.show (var.paramIndex + 1)
                    }
                    queryFragment
              )
              fragments
        ++  "\""

let renderHaddock
    : Project.QueryFragments -> Text
    = Prelude.Text.concatMap
        Project.QueryFragment
        ( \(queryFragment : Project.QueryFragment) ->
            merge
              { Sql = Prelude.Function.identity Text
              , Var = \(var : Project.Var) -> "\$" ++ var.rawName
              }
              queryFragment
        )

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Deps.Lude.Compiled.ok
          Output
          { exp = renderExp input, haddock = renderHaddock input }

in  Algebra.module Input Output run
