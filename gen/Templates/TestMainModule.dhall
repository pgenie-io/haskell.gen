let Algebra = ./Algebra/package.dhall

let Prelude = ../Deps/Prelude.dhall

let Lude = ../Deps/Lude.dhall

let StringLiteral = ./StringLiteral.dhall

let Migration = { name : Text, sql : Text }

let postgresTag = "postgres:18"

let Params =
      { statementsSpecModuleNamespace : Text, migrations : List Migration }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let runMigrationsBody =
                if    Prelude.List.null Migration params.migrations
                then  "pure ()"
                else  Prelude.Text.concatMapSep
                        ''

                        >>
                        ''
                        Migration
                        ( \(migration : Migration) ->
                            ''
                            ( Session.script
                              ${Lude.Text.indentNonEmpty
                                  4
                                  (StringLiteral.run migration.sql)}
                            )''
                        )
                        params.migrations

          in  ''
              module Main where

              import qualified Hasql.Connection.Settings as Settings
              import qualified Hasql.Pool as Pool
              import qualified Hasql.Pool.Config as PoolConfig
              import qualified Hasql.Session as Session
              import Test.Hspec
              import qualified TestcontainersPostgresql as Tcp
              import qualified ${params.statementsSpecModuleNamespace} as StatementsSpec

              main :: IO ()
              main = hspec do
                aroundAllWith
                  ( \action () -> do
                    Tcp.run
                      Tcp.Config
                        { Tcp.tagName = "${postgresTag}"
                        , Tcp.auth = Tcp.TrustAuth
                        , Tcp.forwardLogs = False
                        }
                      ( \(host, port) -> do
                          let connectionSettings =
                                Settings.hostAndPort host port
                                  <> Settings.user "postgres"
                                  <> Settings.dbname "postgres"

                          pool <-
                            Pool.acquire
                              ( PoolConfig.settings
                                  [ PoolConfig.size 10
                                  , PoolConfig.staticConnectionSettings connectionSettings
                                  ]
                              )

                          migrationResult <-
                            Pool.use
                              pool
                              ( ${Lude.Text.indentNonEmpty 14 runMigrationsBody}
                              )

                          case migrationResult of
                            Left err ->
                              fail ("Failed to apply migrations: " ++ show err)

                            Right () ->
                              pure ()

                          action pool

                          Pool.release pool
                      )
                  )
                  StatementsSpec.spec                
              ''
      )
