let Algebra = ./Algebra/package.dhall

let Prelude = ../Deps/Prelude.dhall

let Lude = ../Deps/Lude.dhall

let StringLiteral = ./StringLiteral.dhall

let Migration = { name : Text, sql : Text }

let Params =
      { statementsSpecModuleNamespace : Text, migrations : List Migration }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let runMigrationsBody =
                if    Prelude.List.null Migration params.migrations
                then  "pure ()"
                else  Prelude.Text.concatMapSep
                        "\n"
                        Migration
                        ( \(migration : Migration) ->
                            ''
                            Session.script
                              ${Lude.Text.indentNonEmpty
                                  2
                                  (StringLiteral.run migration.sql)}''
                        )
                        params.migrations

          in  ''
              module Main where

              import qualified Hasql.Connection as Connection
              import qualified Hasql.Connection.Settings as Settings
              import qualified Hasql.Session as Session
              import Test.Hspec (hspec)
              import qualified TestcontainersPostgresql as Tcp
              import qualified ${params.statementsSpecModuleNamespace} as StatementsSpec

              main :: IO ()
              main =
                Tcp.run
                  Tcp.Config
                    { Tcp.tagName = "postgres:18"
                    , Tcp.auth = Tcp.TrustAuth
                    , Tcp.forwardLogs = False
                    }
                  ( \(host, port) -> do
                      let connectionSettings =
                            Settings.hostAndPort host port
                              <> Settings.user "postgres"
                              <> Settings.dbname "postgres"

                      connectionResult <- Connection.acquire connectionSettings

                      case connectionResult of
                        Left err ->
                          fail ("Failed to connect to PostgreSQL: " ++ show err)

                        Right connection -> do
                          migrationResult <- Connection.use connection do
                            ${Lude.Text.indentNonEmpty 14 runMigrationsBody}

                          case migrationResult of
                            Left err ->
                              fail ("Failed to apply migrations: " ++ show err)

                            Right () ->
                              hspec (StatementsSpec.spec connection)

                          Connection.release connection
                  )
              ''
      )
