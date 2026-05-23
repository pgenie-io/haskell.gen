let Algebra = ./Algebra/package.dhall

let Params =
      { moduleNamespace : Text
      , statementName : Text
      , statementsModuleNamespace : Text
      , typesModuleNamespace : Text
      , defaultParams : Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          ''
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
            it "executes with default parameters" $ \pool -> do
              result <- Pool.use pool (Session.statement (${params.defaultParams}) IsStatement.statement)
              result `shouldSatisfy` Either.isRight
          ''
      )
