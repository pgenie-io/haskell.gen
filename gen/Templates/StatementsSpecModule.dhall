let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let StatementSpec = { moduleNamespace : Text, alias : Text }

let Params = { moduleNamespace : Text, statementSpecs : List StatementSpec }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let imports =
                Deps.Prelude.Text.concatMapSep
                  "\n"
                  StatementSpec
                  ( \(statementSpec : StatementSpec) ->
                      "import qualified ${statementSpec.moduleNamespace} as ${statementSpec.alias}"
                  )
                  params.statementSpecs

          let runSpecs =
                Deps.Prelude.Text.concatMapSep
                  "; "
                  StatementSpec
                  ( \(statementSpec : StatementSpec) ->
                      "${statementSpec.alias}.spec connection"
                  )
                  params.statementSpecs

          in  ''
              module ${params.moduleNamespace} (spec) where

              import qualified Hasql.Connection as Connection
              import Test.Hspec (Spec, describe)
              ${imports}

              spec :: Connection.Connection -> Spec
              spec connection = describe "Generated statements" $ do { ${runSpecs} }
              ''
      )
