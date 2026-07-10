let Contract = ../Deps/Contract.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Typeclasses = ../Deps/Typeclasses.dhall

let Sdk = ../Deps/Sdk.dhall

let Templates = ../Templates/package.dhall

let QueryGen = ./Query.dhall

let CustomTypeGen = ./CustomType.dhall

let Config = {}

let Resolved = { rootNamespace : List Text }

let Input = Contract.Project

let Output = List Lude.File.Type

let resolve =
      \(input : Input) ->
          { rootNamespace =
            [ input.space.inPascalCase, input.name.inPascalCase ]
          }
        : Resolved

let combineOutputs =
      \(resolved : Resolved) ->
      \(input : Input) ->
      \(queries : List QueryGen.Output) ->
      \(customTypes : List CustomTypeGen.Output) ->
        let projectNamespace = Prelude.Text.concatSep "." resolved.rootNamespace

        let rootNamespace = Prelude.Text.concatSep "." resolved.rootNamespace

        let customTypeFiles
            : List Lude.File.Type
            = Prelude.List.map
                CustomTypeGen.Output
                Lude.File.Type
                ( \(customType : CustomTypeGen.Output) ->
                    { path = customType.modulePath
                    , content = customType.moduleContent
                    }
                )
                customTypes

        let statementFiles
            : List Lude.File.Type
            = Prelude.List.map
                QueryGen.Output
                Lude.File.Type
                ( \(query : QueryGen.Output) ->
                    { path = query.statementModulePath
                    , content = query.statementModuleContents
                    }
                )
                queries

        let testStatementFiles
            : List Lude.File.Type
            = Prelude.List.map
                QueryGen.Output
                Lude.File.Type
                ( \(query : QueryGen.Output) ->
                    { path = query.statementTestModulePath
                    , content = query.statementTestModuleContents
                    }
                )
                queries

        let preludeFile
            : Lude.File.Type
            = { path =
                  Templates.ModulePath.run
                    { namespace = resolved.rootNamespace # [ "Prelude" ] }
              , content = Templates.PreludeModule.run { projectNamespace }
              }

        let statementsSpecModuleNamespace = rootNamespace ++ ".StatementsSpec"

        let statementsSpecFile
            : Lude.File.Type
            = { path =
                      "test/"
                  ++  Prelude.Text.concatSep
                        "/"
                        (resolved.rootNamespace # [ "StatementsSpec" ])
                  ++  ".hs"
              , content =
                  Templates.StatementsSpecModule.run
                    { moduleNamespace = statementsSpecModuleNamespace
                    , statementsModuleNamespace = rootNamespace ++ ".Statements"
                    , statementSpecs =
                        Prelude.List.map
                          QueryGen.Output
                          Text
                          ( \(query : QueryGen.Output) ->
                              query.statementModuleName
                          )
                          queries
                    }
              }

        let testMainFile
            : Lude.File.Type
            = { path = "test/Main.hs"
              , content =
                  Templates.TestMainModule.run
                    { statementsSpecModuleNamespace
                    , migrations = input.migrations
                    }
              }

        let customTypesFile
            : Lude.File.Type
            = { path =
                  Templates.ModulePath.run
                    { namespace = resolved.rootNamespace # [ "Types" ] }
              , content =
                  Templates.ReexportModule.run
                    { haddock = None Text
                    , namespace = rootNamespace ++ ".Types"
                    , reexportedModules =
                        Prelude.List.map
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
            : Lude.File.Type
            = { path =
                  Templates.ModulePath.run
                    { namespace = resolved.rootNamespace # [ "Statements" ] }
              , content =
                  Templates.ReexportModule.run
                    { haddock = Some
                        ''
                        Mappings to all queries in the project.

                        Hasql statements are provided by the 'Hasql.Mapping.IsStatement' typeclass instances indexed by the statement parameter type.
                        ''
                    , namespace = rootNamespace ++ ".Statements"
                    , reexportedModules =
                        Prelude.List.map
                          QueryGen.Output
                          Templates.ReexportModule.ReexportedModule
                          ( \(query : QueryGen.Output) ->
                              query.statementsModuleReexportedModule
                          )
                          queries
                    }
              }

        let cabalFile
            : Lude.File.Type
            = let packageName =
                    input.space.inKebabCase ++ "-" ++ input.name.inKebabCase

              let path = packageName ++ ".cabal"

              let content =
                    Templates.CabalFile.run
                      { packageName
                      , rootNamespace
                      , statementModuleNames =
                          Prelude.List.map
                            QueryGen.Output
                            Text
                            ( \(query : QueryGen.Output) ->
                                query.statementModuleName
                            )
                            queries
                      , statementTestModuleNames =
                          Prelude.List.map
                            QueryGen.Output
                            Text
                            ( \(query : QueryGen.Output) ->
                                query.statementTestModuleName
                            )
                            queries
                      , customTypeNames =
                          Prelude.List.map
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
            : List Lude.File.Type

let run =
      \(config : Config) ->
      \(input : Input) ->
        let resolvedConfig = resolve input

        let compiledQueries
            : Lude.Compiled.Type (List (Optional QueryGen.Output))
            = Lude.Compiled.traverseList
                Contract.Query
                (Optional QueryGen.Output)
                ( \(query : Contract.Query) ->
                    Typeclasses.Classes.Alternative.optional
                      Lude.Compiled.Type
                      Lude.Compiled.alternative
                      QueryGen.Output
                      (QueryGen.run resolvedConfig.{ rootNamespace } query)
                )
                input.queries

        let compiledQueries
            : Lude.Compiled.Type (List QueryGen.Output)
            = Lude.Compiled.map
                (List (Optional QueryGen.Output))
                (List QueryGen.Output)
                (Prelude.List.unpackOptionals QueryGen.Output)
                compiledQueries

        let compiledTypes
            : Lude.Compiled.Type (List CustomTypeGen.Output)
            = Lude.Compiled.traverseList
                Contract.CustomType
                CustomTypeGen.Output
                (CustomTypeGen.run resolvedConfig.{ rootNamespace })
                input.customTypes

        let files
            : Lude.Compiled.Type (List Lude.File.Type)
            = Lude.Compiled.map2
                (List QueryGen.Output)
                (List CustomTypeGen.Output)
                (List Lude.File.Type)
                (combineOutputs resolvedConfig input)
                compiledQueries
                compiledTypes

        in  files

in  Sdk.Sigs.interpreter Config Input Output run
