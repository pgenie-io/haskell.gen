let Deps = ../Deps/package.dhall

let ResolvedTarget = ../ResolvedTarget.dhall

let Contract = Deps.Contract

let Templates = ../Templates/package.dhall

let QueryGen = ./Query.dhall

let CustomTypeGen = ./CustomType.dhall

let Input = Contract.Project

let Output = List Deps.Lude.File.Type

let combineOutputs =
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
      \(queries : List QueryGen.Output) ->
      \(customTypes : List CustomTypeGen.Output) ->
        let projectNamespace =
              Deps.Prelude.Text.concatSep "." config.rootNamespace

        let rootNamespace = Deps.Prelude.Text.concatSep "." config.rootNamespace

        let customTypeFiles
            : List Deps.Lude.File.Type
            = Deps.Prelude.List.map
                CustomTypeGen.Output
                Deps.Lude.File.Type
                ( \(customType : CustomTypeGen.Output) ->
                    { path = customType.modulePath
                    , content = customType.moduleContent
                    }
                )
                customTypes

        let statementFiles
            : List Deps.Lude.File.Type
            = Deps.Prelude.List.map
                QueryGen.Output
                Deps.Lude.File.Type
                ( \(query : QueryGen.Output) ->
                    { path = query.statementModulePath
                    , content = query.statementModuleContents
                    }
                )
                queries

        let testStatementFiles
            : List Deps.Lude.File.Type
            = Deps.Prelude.List.map
                QueryGen.Output
                Deps.Lude.File.Type
                ( \(query : QueryGen.Output) ->
                    { path = query.statementTestModulePath
                    , content = query.statementTestModuleContents
                    }
                )
                queries

        let preludeFile
            : Deps.Lude.File.Type
            = { path =
                  Templates.ModulePath.run
                    { namespace = config.rootNamespace # [ "Prelude" ] }
              , content = Templates.PreludeModule.run { projectNamespace }
              }

        let statementsSpecModuleNamespace = rootNamespace ++ ".StatementsSpec"

        let statementsSpecFile
            : Deps.Lude.File.Type
            = { path =
                      "test/"
                  ++  Deps.Prelude.Text.concatSep
                        "/"
                        (config.rootNamespace # [ "StatementsSpec" ])
                  ++  ".hs"
              , content =
                  Templates.StatementsSpecModule.run
                    { moduleNamespace = statementsSpecModuleNamespace
                    , statementsModuleNamespace = rootNamespace ++ ".Statements"
                    , statementSpecs =
                        Deps.Prelude.List.map
                          QueryGen.Output
                          Text
                          ( \(query : QueryGen.Output) ->
                              query.statementModuleName
                          )
                          queries
                    }
              }

        let testMainFile
            : Deps.Lude.File.Type
            = { path = "test/Main.hs"
              , content =
                  Templates.TestMainModule.run
                    { statementsSpecModuleNamespace
                    , migrations = input.migrations
                    }
              }

        let customTypesFile
            : Deps.Lude.File.Type
            = { path =
                  Templates.ModulePath.run
                    { namespace = config.rootNamespace # [ "Types" ] }
              , content =
                  Templates.ReexportModule.run
                    { haddock = None Text
                    , namespace = rootNamespace ++ ".Types"
                    , reexportedModules =
                        Deps.Prelude.List.map
                          CustomTypeGen.Output
                          Templates.ReexportModule.ReexportedModule
                          ( \(customType : CustomTypeGen.Output) ->
                              { header = None Text
                              , namespace = customType.moduleNamespace
                              }
                          )
                          customTypes
                    }
              }

        let statementsFile
            : Deps.Lude.File.Type
            = { path =
                  Templates.ModulePath.run
                    { namespace = config.rootNamespace # [ "Statements" ] }
              , content =
                  Templates.ReexportModule.run
                    { haddock = Some
                        ''
                        Mappings to all queries in the project.

                        Hasql statements are provided by the 'Hasql.Mapping.IsStatement' typeclass instances indexed by the statement parameter type.
                        ''
                    , namespace = rootNamespace ++ ".Statements"
                    , reexportedModules =
                        Deps.Prelude.List.map
                          QueryGen.Output
                          Templates.ReexportModule.ReexportedModule
                          ( \(query : QueryGen.Output) ->
                              query.statementsModuleReexportedModule
                          )
                          queries
                    }
              }

        let cabalFile
            : Deps.Lude.File.Type
            = let packageName =
                    input.space.inKebabCase ++ "-" ++ input.name.inKebabCase

              let path = packageName ++ ".cabal"

              let content =
                    Templates.CabalFile.run
                      { packageName
                      , rootNamespace
                      , statementModuleNames =
                          Deps.Prelude.List.map
                            QueryGen.Output
                            Text
                            ( \(query : QueryGen.Output) ->
                                query.statementModuleName
                            )
                            queries
                      , statementTestModuleNames =
                          Deps.Prelude.List.map
                            QueryGen.Output
                            Text
                            ( \(query : QueryGen.Output) ->
                                query.statementTestModuleName
                            )
                            queries
                      , customTypeNames =
                          Deps.Prelude.List.map
                            CustomTypeGen.Output
                            Text
                            ( \(customType : CustomTypeGen.Output) ->
                                customType.moduleName
                            )
                            customTypes
                      , version =
                              "0."
                          ++  Natural/show input.version.major
                          ++  "."
                          ++  Natural/show input.version.minor
                          ++  "."
                          ++  Natural/show input.version.patch
                      , dbName = input.name.inSnakeCase
                      }

              in  { path, content }

        in      [ cabalFile
                , preludeFile
                , customTypesFile
                , statementsFile
                , statementsSpecFile
                , testMainFile
                ]
              # customTypeFiles
              # statementFiles
              # testStatementFiles
            : List Deps.Lude.File.Type

let run =
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
        let compiledQueries
            : Deps.Lude.Compiled.Type (List (Optional QueryGen.Output))
            = Deps.Lude.Compiled.traverseList
                Contract.Query
                (Optional QueryGen.Output)
                ( \(query : Contract.Query) ->
                    Deps.Typeclasses.Classes.Alternative.optional
                      Deps.Lude.Compiled.Type
                      Deps.Lude.Compiled.alternative
                      QueryGen.Output
                      (QueryGen.run config query)
                )
                input.queries

        let compiledQueries
            : Deps.Lude.Compiled.Type (List QueryGen.Output)
            = Deps.Lude.Compiled.map
                (List (Optional QueryGen.Output))
                (List QueryGen.Output)
                (Deps.Prelude.List.unpackOptionals QueryGen.Output)
                compiledQueries

        let compiledTypes
            : Deps.Lude.Compiled.Type (List CustomTypeGen.Output)
            = Deps.Lude.Compiled.traverseList
                Contract.CustomType
                CustomTypeGen.Output
                (CustomTypeGen.run config)
                input.customTypes

        let files
            : Deps.Lude.Compiled.Type (List Deps.Lude.File.Type)
            = Deps.Lude.Compiled.map2
                (List QueryGen.Output)
                (List CustomTypeGen.Output)
                (List Deps.Lude.File.Type)
                (combineOutputs config input)
                compiledQueries
                compiledTypes

        in  files

in  Deps.Sdk.Sigs.Interpreter.module ResolvedTarget.Type Input Output run
