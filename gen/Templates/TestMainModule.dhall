let Sdk = ../Deps/Sdk.dhall

let Prelude = ../Deps/Prelude.dhall

let Lude = ../Deps/Lude.dhall

let StringLiteral = ./StringLiteral.dhall

let Migration = { name : Text, sql : Text }

let postgresTag = "postgres:18"

let Params =
      { statementsSpecModuleNamespace : Text, migrations : List Migration }

in  Sdk.Sigs.Template.module
      Params
      ( \(params : Params) ->
          let runMigrationsBody =
                if    Prelude.List.null Migration params.migrations
                then  "pure ()"
                else  ''
                      do
                        ${Lude.Text.indentNonEmpty
                            2
                            ( Prelude.Text.concatMapSep
                                "\n"
                                Migration
                                ( \(migration : Migration) ->
                                    ''
                                    Hasql.Session.script
                                      ${Lude.Text.indentNonEmpty
                                          4
                                          (StringLiteral.run migration.sql)}''
                                )
                                params.migrations
                            )}''

          in  ''
              module Main where

              import qualified Hasql.Connection.Settings
              import qualified Hasql.Pool
              import qualified Hasql.Pool.Config
              import qualified Hasql.Session
              import Test.Hspec
              import qualified TestcontainersPostgresql
              import qualified ${params.statementsSpecModuleNamespace}

              main :: IO ()
              main = hspec do
                aroundAllWith
                  ( \action () -> do
                    TestcontainersPostgresql.run
                      TestcontainersPostgresql.Config
                        { TestcontainersPostgresql.tagName = "${postgresTag}"
                        , TestcontainersPostgresql.auth = TestcontainersPostgresql.TrustAuth
                        , TestcontainersPostgresql.forwardLogs = False
                        }
                      ( \(host, port) -> do
                          let connectionSettings =
                                Hasql.Connection.Settings.hostAndPort host port
                                  <> Hasql.Connection.Settings.user "postgres"
                                  <> Hasql.Connection.Settings.dbname "postgres"

                          pool <-
                            Hasql.Pool.acquire
                              ( Hasql.Pool.Config.settings
                                  [ Hasql.Pool.Config.size 10
                                  , Hasql.Pool.Config.staticConnectionSettings connectionSettings
                                  ]
                              )

                          migrationResult <-
                            Hasql.Pool.use
                              pool
                              ( ${Lude.Text.indentNonEmpty 18 runMigrationsBody}
                              )

                          case migrationResult of
                            Left err ->
                              fail ("Failed to apply migrations: " ++ show err)

                            Right () ->
                              pure ()

                          action pool

                          Hasql.Pool.release pool
                      )
                  )
                  ${params.statementsSpecModuleNamespace}.spec
              ''
      )
