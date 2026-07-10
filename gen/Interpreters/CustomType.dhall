let InterpreterConfig = ../InterpreterConfig.dhall

let Contract = ../Deps/Contract.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Sdk = ../Deps/Sdk.dhall

let Templates = ../Templates/package.dhall

let MemberGen = ./Member.dhall

let Input = Contract.CustomType

let Output =
      { moduleName : Text
      , moduleNamespace : Text
      , modulePath : Text
      , moduleContent : Text
      }

let run =
      \(config : InterpreterConfig.Type) ->
      \(input : Input) ->
        let moduleName = input.name.inPascalCase

        let moduleNamespaceAsList =
              config.rootNamespace # [ "Types", input.name.inPascalCase ]

        let moduleNamespace =
              Prelude.Text.concatSep "." moduleNamespaceAsList

        let modulePath =
              Templates.ModulePath.run { namespace = moduleNamespaceAsList }

        let preludeModuleName =
              Prelude.Text.concatSep "." (config.rootNamespace # [ "Prelude" ])

        in  merge
              { Composite =
                  \(members : List Contract.Member) ->
                    let compiledMembers
                        : Lude.Compiled.Type (List MemberGen.Output)
                        = Lude.Compiled.traverseList
                            Contract.Member
                            MemberGen.Output
                            (MemberGen.run config)
                            members

                    let customTypeModules
                        : List Text
                        = Prelude.List.mapMaybe
                            Contract.Member
                            Text
                            ( \(member : Contract.Member) ->
                                merge
                                  { Primitive =
                                      \(_ : Contract.Primitive) -> None Text
                                  , Custom =
                                      \(name : Contract.Name) ->
                                        Some
                                          ( Prelude.Text.concatSep
                                              "."
                                              (   config.rootNamespace
                                                # [ "Types", name.inPascalCase ]
                                              )
                                          )
                                  }
                                  member.value.scalar
                            )
                            members

                    let compiledOutput
                        : Lude.Compiled.Type Output
                        = Lude.Compiled.map
                            (List MemberGen.Output)
                            Output
                            ( \(members : List MemberGen.Output) ->
                                { moduleName
                                , moduleNamespace
                                , modulePath
                                , moduleContent =
                                    Templates.CustomCompositeTypeModule.run
                                      { preludeModuleName
                                      , moduleName = moduleNamespace
                                      , typeName = moduleName
                                      , pgSchema = input.pgSchema
                                      , pgTypeName = input.pgName
                                      , customTypeModules
                                      , fieldNames =
                                          Prelude.List.map
                                            MemberGen.Output
                                            Text
                                            ( \(member : MemberGen.Output) ->
                                                member.fieldName
                                            )
                                            members
                                      , fieldDeclarations =
                                          Prelude.List.map
                                            MemberGen.Output
                                            Text
                                            ( \(member : MemberGen.Output) ->
                                                member.fieldDeclaration
                                            )
                                            members
                                      , fieldEncoderExps =
                                          Prelude.List.map
                                            MemberGen.Output
                                            Text
                                            ( \(member : MemberGen.Output) ->
                                                member.fieldEncoder
                                                  "Hasql.Encoders.field"
                                            )
                                            members
                                      , fieldDecoderExps =
                                          Prelude.List.map
                                            MemberGen.Output
                                            Text
                                            ( \(member : MemberGen.Output) ->
                                                member.fieldDecoder
                                            )
                                            members
                                      }
                                }
                            )
                            compiledMembers

                    in  compiledOutput
              , Enum =
                  \(variants : List Contract.EnumVariant) ->
                    Lude.Compiled.ok
                      Output
                      { moduleName
                      , moduleNamespace
                      , modulePath
                      , moduleContent =
                          Templates.CustomEnumTypeModule.run
                            { preludeModuleName
                            , moduleName = moduleNamespace
                            , typeName = moduleName
                            , pgSchema = input.pgSchema
                            , pgTypeName = input.pgName
                            , variants =
                                Prelude.List.map
                                  Contract.EnumVariant
                                  Templates.CustomEnumTypeModule.Variant
                                  ( \(variant : Contract.EnumVariant) ->
                                      { name = variant.name.inPascalCase
                                      , pgValue = variant.pgName
                                      }
                                  )
                                  variants
                            }
                      }
              , Domain =
                  \(value : Contract.Value) ->
                    Lude.Compiled.message
                      Output
                      "Domain types are not yet supported."
              }
              input.definition

in  Sdk.Sigs.interpreter InterpreterConfig.Type Input Output run
