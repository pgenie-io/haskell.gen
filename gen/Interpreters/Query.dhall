let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Lude = Deps.Lude

let Typeclasses = Deps.Typeclasses

let Templates = ../Templates/package.dhall

let ResultModule = ./Result.dhall

let QueryFragmentsModule = ./QueryFragments.dhall

let MemberModule = ./Member.dhall

let Input = Deps.Project.Query

let Output =
      { statementModuleName : Text
      , statementModuleNamespace : Text
      , statementModulePath : Text
      , statementModuleContents : Text
      , statementTestModuleName : Text
      , statementTestModuleNamespace : Text
      , statementTestModulePath : Text
      , statementTestModuleContents : Text
      , statementsModuleReexportedModule :
          Templates.ReexportModule.ReexportedModule
      }

let render =
      \(config : Algebra.Config) ->
      \(input : Input) ->
      \(result : ResultModule.Output) ->
      \(fragments : QueryFragmentsModule.Output) ->
      \(params : List MemberModule.Output) ->
        let statementModuleName = input.name.inPascalCase

        let statementModuleNamespaceAsList =
              config.rootNamespace # [ "Statements", statementModuleName ]

        let statementModuleNamespace =
              Deps.Prelude.Text.concatSep "." statementModuleNamespaceAsList

        let statementModulePath =
              Templates.ModulePath.run
                { namespace = statementModuleNamespaceAsList }

        let statementTypeName = statementModuleName

        let statementResultTypeName = statementModuleName ++ "Result"

        let statementTestModuleName = statementModuleName ++ "Spec"

        let statementTestModuleNamespaceAsList =
              config.rootNamespace # [ "Statements", statementTestModuleName ]

        let statementTestModuleNamespace =
              Deps.Prelude.Text.concatSep "." statementTestModuleNamespaceAsList

        let statementTestModulePath =
                  "test/"
              ++  Deps.Prelude.Text.concatSep
                    "/"
                    statementTestModuleNamespaceAsList
              ++  ".hs"

        let result = result statementModuleName

        let projectNamespace =
              Deps.Prelude.Text.concatSep "." config.rootNamespace

        let queryName = input.name.inSnakeCase

        let statementsModuleNamespace = projectNamespace ++ ".Statements"

        let paramsGenerator =
              if    Deps.Prelude.List.null MemberModule.Output params
              then  "pure Statement.${statementModuleName}"
              else      "Statement.${statementModuleName}"
                    ++  " <\$> "
                    ++  Deps.Prelude.Text.concatMapSep
                          " <*> "
                          MemberModule.Output
                          ( \(member : MemberModule.Output) ->
                              member.testArbitraryGen
                          )
                          params

        let identityExpectedResultExp =
              let identityValueNames =
                    Deps.Prelude.List.map
                      MemberModule.Output
                      Text
                      (\(member : MemberModule.Output) -> member.fieldName)
                      params

              in  if    Deps.Prelude.List.null Text identityValueNames
                  then  "Data.Vector.singleton Statement.${statementModuleName}ResultRow"
                  else      "case statementParams of "
                        ++  "Statement.${statementModuleName} "
                        ++  Deps.Prelude.Text.concatSep " " identityValueNames
                        ++  " -> Data.Vector.singleton (Statement.${statementModuleName}ResultRow "
                        ++  Deps.Prelude.Text.concatSep " " identityValueNames
                        ++  ")"

        let statementModuleContents =
              ''
              module ${statementModuleNamespace} where

              import ${projectNamespace}.Prelude
              import qualified Hasql.Statement as Statement
              import qualified Hasql.Decoders as Decoders
              import qualified Hasql.Encoders as Encoders
              import qualified Data.Aeson as Aeson
              import qualified Data.Vector as Vector
              import qualified Hasql.Mapping.IsStatement as IsStatement
              import qualified Hasql.Mapping.IsScalar as IsScalar
              import qualified ${projectNamespace}.Types as Types
              import qualified PostgresqlTypes as Pt

              ${Templates.ParamsTypeDecl.run
                  { queryName
                  , sqlForDocs = fragments.haddock
                  , srcPath = input.srcPath
                  , typeName = statementTypeName
                  , fields =
                      Deps.Prelude.List.map
                        MemberModule.Output
                        Text
                        ( \(member : MemberModule.Output) ->
                            member.fieldDeclaration
                        )
                        params
                  }}
              ${result.typeDecls}
              instance IsStatement.IsStatement ${statementTypeName} where
                type Result ${statementTypeName} = ${statementResultTypeName}

                statement = Statement.preparable sql encoder decoder
                  where
                    sql =
                      ${Deps.Lude.Text.indent 8 fragments.exp}

                    encoder =
                      mconcat
                        [ ${Lude.Text.indent
                              12
                              ( Deps.Prelude.Text.concatMapSep
                                  ''
                                  ,
                                  ''
                                  MemberModule.Output
                                  ( \(member : MemberModule.Output) ->
                                      member.fieldEncoder "Encoders.param"
                                  )
                                  params
                              )}
                        ]

                    decoder =
                      ${Deps.Lude.Text.indent 8 result.decoderExp}

              ''

        let statementTestModuleContents =
              Templates.StatementTestModule.run
                { moduleNamespace = statementTestModuleNamespace
                , statementName = statementModuleName
                , statementsModuleNamespace
                , typesModuleNamespace = projectNamespace ++ ".Types"
                , paramsGenerator
                , shouldTestIdentity = input.identity
                , identityExpectedResultExp
                }

        let statementsModuleReexportedModule =
              { header = Some statementModuleName
              , namespace = statementModuleNamespace
              }

        in  { statementModuleName
            , statementModuleNamespace
            , statementModulePath
            , statementModuleContents
            , statementTestModuleName
            , statementTestModuleNamespace
            , statementTestModulePath
            , statementTestModuleContents
            , statementsModuleReexportedModule
            }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        Deps.Lude.Compiled.nest
          Output
          input.srcPath
          ( Typeclasses.Classes.Applicative.map3
              Deps.Lude.Compiled.Type
              Deps.Lude.Compiled.applicative
              ResultModule.Output
              QueryFragmentsModule.Output
              (List MemberModule.Output)
              Output
              (render config input)
              ( Deps.Lude.Compiled.nest
                  ResultModule.Output
                  "result"
                  (ResultModule.run config input.result)
              )
              ( Deps.Lude.Compiled.nest
                  QueryFragmentsModule.Output
                  "sql"
                  (QueryFragmentsModule.run config input.fragments)
              )
              ( Deps.Lude.Compiled.nest
                  (List MemberModule.Output)
                  "params"
                  ( Typeclasses.Classes.Applicative.traverseList
                      Deps.Lude.Compiled.Type
                      Deps.Lude.Compiled.applicative
                      Deps.Project.Member
                      MemberModule.Output
                      (MemberModule.run config)
                      input.params
                  )
              )
          )

in  Algebra.module Input Output run
