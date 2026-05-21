let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Project = Deps.Project

let Templates = ../Templates/package.dhall

let MemberGen = ./Member.dhall

let Input = Project.CustomType

let Output =
      { moduleName : Text
      , moduleNamespace : Text
      , modulePath : Text
      , moduleContent : Text
      }

in  Algebra.module
      Input
      Output
      ( \(config : Algebra.Config) ->
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
                    \(members : List Project.Member) ->
                      let compiledMembers
                          : Deps.Lude.Compiled.Type (List MemberGen.Output)
                          = Deps.Lude.Compiled.traverseList
                              Project.Member
                              MemberGen.Output
                              (MemberGen.run config)
                              members

                      let customTypeModules
                          : List Text
                          = Deps.Prelude.List.mapMaybe
                              Project.Member
                              Text
                              ( \(member : Project.Member) ->
                                  merge
                                    { Primitive =
                                        \(_ : Project.Primitive) -> None Text
                                    , Custom =
                                        \(name : Project.Name) ->
                                          Some
                                            ( Deps.Prelude.Text.concatSep
                                                "."
                                                (   config.rootNamespace
                                                  # [ "Types"
                                                    , name.inPascalCase
                                                    ]
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
                                                    "Encoders.field"
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
                    \(variants : List Project.EnumVariant) ->
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
                                    Project.EnumVariant
                                    Templates.CustomEnumTypeModule.Variant
                                    ( \(variant : Project.EnumVariant) ->
                                        { name = variant.name.inPascalCase
                                        , pgValue = variant.pgName
                                        }
                                    )
                                    variants
                              }
                        }
                , Domain =
                    \(value : Project.Value) ->
                      Deps.Lude.Compiled.message
                        Output
                        "Domain types are not yet supported."
                }
                input.definition
      )
