let Algebra = ./Algebra/package.dhall

let Prelude = ../Deps/Prelude.dhall

let Lude = ../Deps/Lude.dhall

let Params =
      { statementModuleName : Text
      , moduleNamespace : Text
      , statementsModuleNamespace : Text
      , shouldTestIdentity : Bool
      , identityValueNames : List Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let executesTestCase =
                if    params.shouldTestIdentity
                then  None Text
                else  Some
                        ''
                        it "executes with arbitrary parameters" \pool ->
                          property \statementParams ->
                            ioProperty do
                              result <- Hasql.Pool.use pool (Hasql.Session.statement statementParams Hasql.Mapping.IsStatement.statement)
                              pure (isRight result)''

          let identityTestCase =
                if    params.shouldTestIdentity
                then  let expectedResultExp =
                            if    Prelude.List.null
                                    Text
                                    params.identityValueNames
                            then  "Data.Vector.singleton ${params.statementsModuleNamespace}.${params.statementModuleName}ResultRow"
                            else  let varNames =
                                        Prelude.Text.concatSep
                                          " "
                                          params.identityValueNames

                                  in  ''
                                      case statementParams of
                                        ${params.statementsModuleNamespace}.${params.statementModuleName} ${varNames} ->
                                          Data.Vector.singleton (${params.statementsModuleNamespace}.${params.statementModuleName}ResultRow ${varNames})''

                      in  Some
                            ''
                            it "satisfies identity property" \pool ->
                              property \statementParams ->
                                ioProperty do
                                  result <- Hasql.Pool.use pool (Hasql.Session.statement statementParams Hasql.Mapping.IsStatement.statement)
                                  let expectedResult =
                                        ${Lude.Text.indent 12 expectedResultExp}
                                  pure (result === Right expectedResult)''
                else  None Text

          let cases =
                Prelude.Text.concatSep
                  "\n"
                  ( Prelude.List.unpackOptionals
                      Text
                      [ executesTestCase, identityTestCase ]
                  )

          in  ''
              module ${params.moduleNamespace} (spec) where

              import Data.Either (isRight)
              import qualified Data.Text
              import qualified Data.Vector
              import qualified Hasql.Pool
              import qualified Hasql.Mapping.IsStatement
              import qualified Hasql.Session
              import qualified ${params.statementsModuleNamespace}

              import Test.Hspec
              import Test.QuickCheck
              import Test.QuickCheck.Instances ()

              spec :: SpecWith Hasql.Pool.Pool
              spec = do
                ${Lude.Text.indentNonEmpty 2 cases}
              ''
      )
