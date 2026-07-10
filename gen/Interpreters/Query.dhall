let InterpreterConfig = ../InterpreterConfig.dhall

let Contract = ../Deps/Contract.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Typeclasses = ../Deps/Typeclasses.dhall

let Sdk = ../Deps/Sdk.dhall

let Templates = ../Templates/package.dhall

let ResultModule = ./Result.dhall

let QueryFragmentsModule = ./QueryFragments.dhall

let MemberModule = ./Member.dhall

let Input = Contract.Query

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
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
      \(result : ResultModule.Output) ->
      \(fragments : QueryFragmentsModule.Output) ->
      \(params : List MemberModule.Output) ->
        let statementModuleName = input.name.inPascalCase

        let statementModuleNamespaceAsList =
              config.rootNamespace # [ "Statements", statementModuleName ]

        let statementModuleNamespace =
              Prelude.Text.concatSep "." statementModuleNamespaceAsList

        let statementModulePath =
              Templates.ModulePath.run
                { namespace = statementModuleNamespaceAsList }

        let statementTypeName = statementModuleName

        let statementResultTypeName = statementModuleName ++ "Result"

        let statementTestModuleName = statementModuleName ++ "Spec"

        let statementTestModuleNamespaceAsList =
              config.rootNamespace # [ "Statements", statementTestModuleName ]

        let statementTestModuleNamespace =
              Prelude.Text.concatSep "." statementTestModuleNamespaceAsList

        let statementTestModulePath =
                  "test/"
              ++  Prelude.Text.concatSep
                    "/"
                    statementTestModuleNamespaceAsList
              ++  ".hs"

        let result = result statementModuleName

        let projectNamespace =
              Prelude.Text.concatSep "." config.rootNamespace

        let queryName = input.name.inSnakeCase

        let statementsModuleNamespace = projectNamespace ++ ".Statements"

        let identityValueNames =
              Prelude.List.map
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
                    Prelude.List.map
                      MemberModule.Output
                      Text
                      ( \(member : MemberModule.Output) ->
                          member.fieldDeclaration
                      )
                      params
                , resultTypeDecls = result.typeDecls
                , statementArbitraryGens =
                    Prelude.List.map
                      MemberModule.Output
                      Text
                      ( \(member : MemberModule.Output) ->
                          member.testArbitraryGen
                      )
                      params
                , sqlExp = fragments.exp
                , encoderExps =
                    Prelude.List.map
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
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
        Lude.Compiled.nest
          Output
          input.srcPath
          ( Typeclasses.Classes.Applicative.map3
              Lude.Compiled.Type
              Lude.Compiled.applicative
              ResultModule.Output
              QueryFragmentsModule.Output
              (List MemberModule.Output)
              Output
              (render config input)
              ( Lude.Compiled.nest
                  ResultModule.Output
                  "result"
                  (ResultModule.run config input.result)
              )
              ( Lude.Compiled.nest
                  QueryFragmentsModule.Output
                  "sql"
                  (QueryFragmentsModule.run config input.fragments)
              )
              ( Lude.Compiled.nest
                  (List MemberModule.Output)
                  "params"
                  ( Typeclasses.Classes.Applicative.traverseList
                      Lude.Compiled.Type
                      Lude.Compiled.applicative
                      Contract.Member
                      MemberModule.Output
                      (MemberModule.run config)
                      input.params
                  )
              )
          )

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
