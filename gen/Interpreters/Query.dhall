let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Typeclasses = ../Deps/Typeclasses.dhall

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

        let identityValueNames =
              Deps.Prelude.List.map
                MemberModule.Output
                Text
                (\(member : MemberModule.Output) -> member.fieldName)
                params

        let statementModuleContents =
              Templates.StatementModule.run
                { moduleNamespace = statementModuleNamespace
                , projectNamespace
                , queryName
                , srcPath = input.srcPath
                , statementTypeName
                , statementResultTypeName
                , sqlForDocs = fragments.haddock
                , statementParamsFields =
                    Deps.Prelude.List.map
                      MemberModule.Output
                      Text
                      ( \(member : MemberModule.Output) ->
                          member.fieldDeclaration
                      )
                      params
                , resultTypeDecls = result.typeDecls
                , statementArbitraryGens =
                    Deps.Prelude.List.map
                      MemberModule.Output
                      Text
                      ( \(member : MemberModule.Output) ->
                          member.testArbitraryGen
                      )
                      params
                , sqlExp = fragments.exp
                , encoderExps =
                    Deps.Prelude.List.map
                      MemberModule.Output
                      Text
                      ( \(member : MemberModule.Output) ->
                          member.fieldEncoder "Hasql.Encoders.param"
                      )
                      params
                , decoderExp = result.decoderExp
                }

        let statementTestModuleContents =
              Templates.StatementTestModule.run
                { moduleNamespace = statementTestModuleNamespace
                , statementModuleName
                , statementsModuleNamespace
                , shouldTestIdentity = input.identity
                , identityValueNames
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
