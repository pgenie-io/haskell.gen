let Deps = ../Deps/package.dhall

let ResolvedTarget = ../ResolvedTarget.dhall

let Contract = Deps.Contract

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
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
        let moduleName = input.name.inPascalCase

        let moduleNamespaceAsList =
              config.rootNamespace # [ "Types", input.name.inPascalCase ]

        let moduleNamespace =
              Deps.Prelude.Text.concatSep "." moduleNamespaceAsList

        let modulePath =
              Templates.ModulePath.run { namespace = moduleNamespaceAsList }

        let preludeModuleName =
              Deps.Prelude.Text.concatSep
                "."
                (config.rootNamespace # [ "Prelude" ])

        in  merge
              { Composite =
                  \(members : List Contract.Member) ->
                    let compiledMembers
                        : Deps.Lude.Compiled.Type (List MemberGen.Output)
                        = Deps.Lude.Compiled.traverseList
                            Contract.Member
                            MemberGen.Output
                            (MemberGen.run config)
                            members

                    let customTypeModules
                        : List Text
                        = Deps.Prelude.List.mapMaybe
                            Contract.Member
                            Text
                            ( \(member : Contract.Member) ->
                                merge
                                  { Primitive =
                                      \(_ : Contract.Primitive) -> None Text
                                  , Custom =
                                      \(name : Contract.Name) ->
                                        Some
                                          ( Deps.Prelude.Text.concatSep
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
                        : Deps.Lude.Compiled.Type Output
                        = Deps.Lude.Compiled.map
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
                                          Deps.Prelude.List.map
                                            MemberGen.Output
                                            Text
                                            ( \(member : MemberGen.Output) ->
                                                member.fieldName
                                            )
                                            members
                                      , fieldDeclarations =
                                          Deps.Prelude.List.map
                                            MemberGen.Output
                                            Text
                                            ( \(member : MemberGen.Output) ->
                                                member.fieldDeclaration
                                            )
                                            members
                                      , fieldEncoderExps =
                                          Deps.Prelude.List.map
                                            MemberGen.Output
                                            Text
                                            ( \(member : MemberGen.Output) ->
                                                member.fieldEncoder
                                                  "Hasql.Encoders.field"
                                            )
                                            members
                                      , fieldDecoderExps =
                                          Deps.Prelude.List.map
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
                    Deps.Lude.Compiled.ok
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
                                Deps.Prelude.List.map
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
                    Deps.Lude.Compiled.message
                      Output
                      "Domain types are not yet supported."
              }
              input.definition

in  Deps.Sdk.Sigs.Interpreter.module ResolvedTarget.Type Input Output run
