let Deps = ../Deps/package.dhall

let ResolvedTarget = ../ResolvedTarget.dhall

let Prelude = Deps.Prelude

let Contract = Deps.Contract

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
                          "\$" ++ Deps.Prelude.Natural.show (var.paramIndex + 1)
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
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
        Deps.Lude.Compiled.ok
          Output
          { exp = renderExp input, haddock = renderHaddock input }

in  Deps.Sdk.Sigs.Interpreter.module ResolvedTarget.Type Input Output run
