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
          import qualified Hasql.Connection as Connection
          import qualified Hasql.Mapping.IsStatement as IsStatement
          import qualified Hasql.Session as Session
          import Test.Hspec
          import qualified ${params.statementsModuleNamespace} as Statement
          import qualified ${params.typesModuleNamespace} as Types

          spec :: Connection.Connection -> Spec
          spec connection =
            describe "${params.statementName}" do
              it "executes with default parameters" do
                result <- Connection.use connection (Session.statement (${params.defaultParams}) IsStatement.statement)
                result `shouldSatisfy` Either.isRight
          ''
      )
