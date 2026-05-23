let Algebra = ./Algebra/package.dhall

let Lude = ../Deps/Lude.dhall

let Params =
      { moduleNamespace : Text
      , statementName : Text
      , statementsModuleNamespace : Text
      , typesModuleNamespace : Text
      , paramsGenerator : Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let propertyCase =
                ''
                it "executes with arbitrary parameters" $ \pool ->
                  property $
                    forAll
                      (${params.paramsGenerator})
                      (\statementParams ->
                        ioProperty $ do
                          _ <- Pool.use pool (Session.statement statementParams IsStatement.statement)
                          pure True
                      )
                ''

          in  ''
              module ${params.moduleNamespace} (spec) where

              import qualified Data.Either as Either
              import qualified Data.Vector as Data.Vector
              import qualified Hasql.Pool as Pool
              import qualified Hasql.Mapping.IsStatement as IsStatement
              import qualified Hasql.Session as Session
              import Test.Hspec
              import Test.QuickCheck (arbitrary, forAll, frequency, ioProperty, listOf, property)
              import Test.QuickCheck.Instances ()
              import qualified ${params.statementsModuleNamespace} as Statement
              import qualified ${params.typesModuleNamespace} as Types

              spec :: SpecWith Pool.Pool
              spec = do
                ${Lude.Text.indentNonEmpty 2 propertyCase}
              ''
      )
