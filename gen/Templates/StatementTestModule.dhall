let Algebra = ./Algebra/package.dhall

let Prelude = ../Deps/Prelude.dhall

let Lude = ../Deps/Lude.dhall

let TestCase = { description : Text, params : Text }

let Params =
      { moduleNamespace : Text
      , statementName : Text
      , statementsModuleNamespace : Text
      , typesModuleNamespace : Text
      , defaultParamsCases : List TestCase
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let testCases =
                Prelude.Text.concatMapSep
                  "\n"
                  TestCase
                  ( \(testCase : TestCase) ->
                      let caseLine =
                            "it \"${testCase.description}\" $ \\pool -> do"

                      let bodyLine =
                            "  result <- Pool.use pool (Session.statement (${testCase.params}) IsStatement.statement)"

                      let resultLine = "  result `shouldSatisfy` Either.isRight"

                      in  "${caseLine}\n${bodyLine}\n${resultLine}"
                  )
                  params.defaultParamsCases

          in  ''
              module ${params.moduleNamespace} (spec) where

              import qualified Data.Either as Either
              import qualified Data.UUID as Data.UUID
              import qualified Hasql.Pool as Pool
              import qualified Hasql.Mapping.IsStatement as IsStatement
              import qualified Hasql.Session as Session
              import Test.Hspec
              import qualified ${params.statementsModuleNamespace} as Statement
              import qualified ${params.typesModuleNamespace} as Types

              spec :: SpecWith Pool.Pool
              spec = do
                ${Lude.Text.indentNonEmpty 2 testCases}
              ''
      )
