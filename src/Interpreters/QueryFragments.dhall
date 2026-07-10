let Prelude = ../Deps/Prelude.dhall

let Lude = ../Deps/Lude.dhall

let Contract = ../Deps/Contract.dhall

let Sdk = ../Deps/Sdk.dhall

let Config = { rootNamespace : List Text }

let Input = Contract.QueryFragments

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
    : Contract.QueryFragments -> Text
    = \(fragments : Contract.QueryFragments) ->
            "\""
        ++  Prelude.Text.concatMap
              Contract.QueryFragment
              ( \(queryFragment : Contract.QueryFragment) ->
                  merge
                    { Sql = escapeText
                    , Var =
                        \(var : Contract.Var) ->
                          "\$" ++ Prelude.Natural.show (var.paramIndex + 1)
                    }
                    queryFragment
              )
              fragments
        ++  "\""

let renderHaddock
    : Contract.QueryFragments -> Text
    = Prelude.Text.concatMap
        Contract.QueryFragment
        ( \(queryFragment : Contract.QueryFragment) ->
            merge
              { Sql = Prelude.Function.identity Text
              , Var = \(var : Contract.Var) -> "\$" ++ var.rawName
              }
              queryFragment
        )

let run =
      \(config : Config) ->
      \(input : Input) ->
        Lude.Compiled.ok
          Output
          { exp = renderExp input, haddock = renderHaddock input }

in  Sdk.Sigs.interpreter Config Input Output run
