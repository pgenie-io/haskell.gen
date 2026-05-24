let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Lude = ../Deps/Lude.dhall

let ParamsTypeDecl = ./ParamsTypeDecl.dhall

let Params =
      { moduleNamespace : Text
      , projectNamespace : Text
      , queryName : Text
      , srcPath : Text
      , statementTypeName : Text
      , statementResultTypeName : Text
      , sqlForDocs : Text
      , statementParamsFields : List Text
      , resultTypeDecls : Text
      , statementArbitraryGens : List Text
      , sqlExp : Text
      , encoderExps : List Text
      , decoderExp : Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let statementArbitraryExp =
                if    Deps.Prelude.List.null Text params.statementArbitraryGens
                then  "pure ${params.statementTypeName}"
                else  ''
                      ${params.statementTypeName}
                        ${Lude.Text.indent
                            2
                            ''
                            <$> ${Deps.Prelude.Text.concatMapSep
                                    ''

                                    <*> ''
                                    Text
                                    (\(gen : Text) -> Lude.Text.indent 4 gen)
                                    params.statementArbitraryGens}
                            ''}''

          let statementArbitraryInstance =
                ''
                instance Arbitrary ${params.statementTypeName} where
                  arbitrary =
                    ${Lude.Text.indentNonEmpty 4 statementArbitraryExp}''

          in  ''
              module ${params.moduleNamespace} where

              import ${params.projectNamespace}.Prelude
              import Test.QuickCheck
              import qualified Hasql.Statement
              import qualified Hasql.Decoders
              import qualified Hasql.Encoders
              import qualified Data.Aeson
              import qualified Data.Vector
              import qualified Hasql.Mapping.IsStatement
              import qualified Hasql.Mapping.IsScalar
              import ${params.projectNamespace}.Types
              import qualified PostgresqlTypes
              import qualified PostgresqlTypes.Date
              import qualified PostgresqlTypes.Bytea
              import qualified PostgresqlTypes.Numeric
              import qualified PostgresqlTypes.Float4
              import qualified PostgresqlTypes.Float8
              import qualified PostgresqlTypes.Int2
              import qualified PostgresqlTypes.Int4
              import qualified PostgresqlTypes.Int8
              import qualified PostgresqlTypes.Text
              import qualified PostgresqlTypes.Uuid

              ${ParamsTypeDecl.run
                  { queryName = params.queryName
                  , sqlForDocs = params.sqlForDocs
                  , srcPath = params.srcPath
                  , typeName = params.statementTypeName
                  , fields = params.statementParamsFields
                  }}
              ${params.resultTypeDecls}
              ${statementArbitraryInstance}
              instance Hasql.Mapping.IsStatement.IsStatement ${params.statementTypeName} where
                type Result ${params.statementTypeName} = ${params.statementResultTypeName}

                statement = Hasql.Statement.preparable sql encoder decoder
                  where
                    sql =
                      ${Lude.Text.indent 8 params.sqlExp}

                    encoder =
                      mconcat
                        [ ${Lude.Text.indent
                              12
                              ( Deps.Prelude.Text.concatSep
                                  ''
                                  ,
                                  ''
                                  params.encoderExps
                              )}
                        ]

                    decoder =
                      ${Lude.Text.indent 8 params.decoderExp}
              ''
      )
