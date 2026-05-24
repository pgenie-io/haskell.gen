let Algebra = ./Algebra/package.dhall

let Prelude = ../Deps/Prelude.dhall

let Lude = ../Deps/Lude.dhall

let Params =
      { moduleNamespace : Text
      , statementName : Text
      , statementsModuleNamespace : Text
      , typesModuleNamespace : Text
      , paramsGenerator : Text
      , shouldTestIdentity : Bool
      , identityExpectedResultExp : Text
      , identityPreconditionExp : Text
      , identityRectangularHelpers : Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let executesTestCase =
                if    params.shouldTestIdentity
                then  None Text
                else  Some
                        ''
                        it "executes with arbitrary parameters" $ \pool ->
                          property $
                            forAll
                              (${params.paramsGenerator})
                              (\statementParams ->
                                ioProperty $ do
                                  _ <- Pool.use pool (Session.statement statementParams IsStatement.statement)
                                  pure True
                              )''

          let identityTestCase =
                if    params.shouldTestIdentity
                then  Some
                        ''
                        it "satisfies identity property" $ \pool ->
                          property $
                            forAll
                              (${params.paramsGenerator})
                              (\statementParams ->
                                (${params.identityPreconditionExp}) ==>
                                  ioProperty (do
                                    result <- Pool.use pool (Session.statement statementParams IsStatement.statement)
                                    pure $
                                      case result of
                                        Right rows -> rows == ${params.identityExpectedResultExp}
                                        Left _ -> False
                                  )
                              )''
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

              import qualified Data.Either as Either
              import qualified Data.Text
              import qualified Data.Vector
              import qualified Hasql.Pool as Pool
              import qualified Hasql.Mapping.IsStatement as IsStatement
              import qualified Hasql.Session as Session
              import qualified ${params.statementsModuleNamespace} as Statement
              import qualified ${params.typesModuleNamespace} as Types

              import Test.Hspec
              import Test.QuickCheck
              import Test.QuickCheck.Instances ()

              spec :: SpecWith Pool.Pool
              spec = do
                ${Lude.Text.indentNonEmpty 2 cases}

              ${params.identityRectangularHelpers}
              ''
      )
