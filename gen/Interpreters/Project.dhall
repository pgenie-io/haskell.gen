let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Project = Deps.Project

let Templates = ../Templates/package.dhall

let QueryGen = ./Query.dhall

let CustomTypeGen = ./CustomType.dhall

let Input = Project.Project

let Output = List Deps.Lude.File.Type

let CustomTypeDefault = { typeName : Text, literal : Text }

let lookupCustomDefaultLiteral =
      \(customTypeDefaults : List CustomTypeDefault) ->
      \(typeName : Text) ->
        let matchingDefaults =
              Deps.Prelude.List.filter
                CustomTypeDefault
                (\(d : CustomTypeDefault) -> Text/equal d.typeName typeName)
                customTypeDefaults

        in  Deps.Prelude.Optional.fold
              CustomTypeDefault
              (Deps.Prelude.List.head CustomTypeDefault matchingDefaults)
              Text
              (\(d : CustomTypeDefault) -> d.literal)
              "(error \"No default value for custom types\")"

let primitiveDefaultLiteral =
      \(primitive : Project.Primitive) ->
        merge
          { Bit = "\"1\""
          , Bool = "True"
          , Box = "\"(0,0),(3,7)\""
          , Bpchar = "\"ABC\""
          , Bytea = "mempty"
          , Char = "\"Z\""
          , Circle = "\"<(1.5,2.5),3>\""
          , Cidr = "\"10.42.0.0/16\""
          , Citext = "(error \"Unsupported type: citext\")"
          , Date = "\"2000-01-01\""
          , Datemultirange = "\"{}\""
          , Daterange = "\"[2000-01-01,2000-01-02)\""
          , Float4 = "3.14"
          , Float8 = "42.5"
          , Geography = "(error \"Unsupported type: geography\")"
          , Geometry = "(error \"Unsupported type: geometry\")"
          , Hstore = "\"\\\"genre\\\"=>\\\"ambient\\\"\""
          , Inet = "\"192.168.10.4/32\""
          , Int2 = "7"
          , Int4 = "42"
          , Int4multirange = "\"{}\""
          , Int4range = "\"[10,20)\""
          , Int8 = "4242"
          , Int8multirange = "\"{}\""
          , Int8range = "\"[100,200)\""
          , Interval = "\"01:23:45\""
          , Json = "\"{\\\"kind\\\":\\\"demo\\\"}\""
          , Jsonb = "\"{\\\"kind\\\":\\\"demo\\\"}\""
          , Line = "\"{1,0,-1}\""
          , Lseg = "\"[(1,2),(3,4)]\""
          , Ltree = "(error \"Unsupported type: ltree\")"
          , Macaddr = "\"08:00:2b:01:02:03\""
          , Macaddr8 = "\"08:00:2b:01:02:03:04:05\""
          , Money = "\"\$12.34\""
          , Name = "(error \"Unsupported type: name\")"
          , Numeric = "\"123.45\""
          , Nummultirange = "\"{}\""
          , Numrange = "\"[1.1,2.2)\""
          , Oid = "\"42\""
          , Path = "\"[(0,0),(1,2),(2,3)]\""
          , PgLsn = "(error \"Unsupported type: pg_lsn\")"
          , PgSnapshot = "(error \"Unsupported type: pg_snapshot\")"
          , Point = "\"(4,5)\""
          , Polygon = "\"((0,0),(2,0),(1,3))\""
          , Text = "mempty"
          , Time = "\"12:34:56\""
          , Timestamp = "\"2000-01-01 12:34:56\""
          , Timestamptz = "\"2000-01-01 12:34:56+00\""
          , Timetz = "\"12:34:56+00\""
          , Tsmultirange = "\"{}\""
          , Tsquery = "(error \"Unsupported type: tsquery\")"
          , Tsrange = "\"[2000-01-01 00:00:00,2000-01-02 00:00:00)\""
          , Tstzmultirange = "\"{}\""
          , Tstzrange = "\"[2000-01-01 00:00:00+00,2000-01-02 00:00:00+00)\""
          , Tsvector = "\"'demo':1\""
          , Uuid = "Data.UUID.nil"
          , Varbit = "\"\""
          , Varchar = "\"\""
          , Xml = "(error \"Unsupported type: xml\")"
          , Box2D = "(error \"Unsupported type: box2d\")"
          , Box3D = "(error \"Unsupported type: box3d\")"
          }
          primitive

let valueDefaultLiteral =
      \(customTypeDefaults : List CustomTypeDefault) ->
      \(value : Project.Value) ->
        Deps.Prelude.Optional.fold
          Project.ArraySettings
          value.arraySettings
          Text
          (\(_ : Project.ArraySettings) -> "mempty")
          ( merge
              { Primitive = primitiveDefaultLiteral
              , Custom =
                  \(name : Project.Name) ->
                    lookupCustomDefaultLiteral
                      customTypeDefaults
                      name.inPascalCase
              }
              value.scalar
          )

let customTypeDefaultLiteral =
      \(customTypeDefaults : List CustomTypeDefault) ->
      \(customType : Project.CustomType) ->
        merge
          { Composite =
              \(members : List Project.Member) ->
                let fieldDefaults =
                      Deps.Prelude.List.map
                        Project.Member
                        Text
                        ( \(member : Project.Member) ->
                            if    member.isNullable
                            then  "Nothing"
                            else  valueDefaultLiteral
                                    customTypeDefaults
                                    member.value
                        )
                        members

                in  if    Deps.Prelude.List.null Text fieldDefaults
                    then  "Types.${customType.name.inPascalCase}"
                    else      "(Types.${customType.name.inPascalCase} "
                          ++  Deps.Prelude.Text.concatSep " " fieldDefaults
                          ++  ")"
          , Enum =
              \(variants : List Project.EnumVariant) ->
                Deps.Prelude.Optional.fold
                  Project.EnumVariant
                  (Deps.Prelude.List.head Project.EnumVariant variants)
                  Text
                  ( \(variant : Project.EnumVariant) ->
                      "Types.${variant.name.inPascalCase}${customType.name.inPascalCase}"
                  )
                  "(error \"No default value for custom enum with no variants\")"
          , Domain =
              \(_ : Project.Value) ->
                "(error \"No default value for custom domain types\")"
          }
          customType.definition

let deriveCustomTypeDefaults =
      \(customTypes : List Project.CustomType) ->
        List/fold
          Project.CustomType
          customTypes
          (List CustomTypeDefault)
          ( \(customType : Project.CustomType) ->
            \(acc : List CustomTypeDefault) ->
                acc
              # [ { typeName = customType.name.inPascalCase
                  , literal = customTypeDefaultLiteral acc customType
                  }
                ]
          )
          ([] : List CustomTypeDefault)

let combineOutputs =
      \(config : Algebra.Config) ->
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
      \(config : Algebra.Config) ->
      \(input : Input) ->
        let configWithCustomTypeDefaults =
              config
              with customTypeDefaults =
                  deriveCustomTypeDefaults input.customTypes

        let compiledQueries
            : Deps.Lude.Compiled.Type (List (Optional QueryGen.Output))
            = Deps.Lude.Compiled.traverseList
                Project.Query
                (Optional QueryGen.Output)
                ( \(query : Project.Query) ->
                    Deps.Typeclasses.Classes.Alternative.optional
                      Deps.Lude.Compiled.Type
                      Deps.Lude.Compiled.alternative
                      QueryGen.Output
                      (QueryGen.run configWithCustomTypeDefaults query)
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
                Project.CustomType
                CustomTypeGen.Output
                (CustomTypeGen.run configWithCustomTypeDefaults)
                input.customTypes

        let files
            : Deps.Lude.Compiled.Type (List Deps.Lude.File.Type)
            = Deps.Lude.Compiled.map2
                (List QueryGen.Output)
                (List CustomTypeGen.Output)
                (List Deps.Lude.File.Type)
                (combineOutputs configWithCustomTypeDefaults input)
                compiledQueries
                compiledTypes

        in  files

in  Algebra.module Input Output run
