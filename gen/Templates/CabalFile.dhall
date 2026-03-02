let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params =
      { packageName : Text
      , rootNamespace : Text
      , customTypeNames : List Text
      , statementModuleNames : List Text
      , version : Text
      , dbName : Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          ''
          cabal-version: 3.4
          name: ${params.packageName}
          version: ${params.version}
          synopsis: Type-safe mapping to the "${params.dbName}" database
          description:
            This package provides type-safe Haskell bindings for the @${params.dbName}@ database.
            It was generated from SQL queries using the [@pGenie@](https://pgenie.io) code generator.

            The package features:

            * Ready-to-use statement definitions for all queries with associated parameter and result types
            * Mappings for PostgreSQL enums and composite types

            All statements are defined using the @hasql-mapping@ library and can be
            executed using the @hasql-execution@ package or directly with @hasql@.

          library
            hs-source-dirs: src

            default-language: Haskell2010

            default-extensions:
              ApplicativeDo, Arrows, BangPatterns, BlockArguments, ConstraintKinds, DataKinds, DefaultSignatures, DeriveAnyClass, DeriveDataTypeable, DeriveFoldable, DeriveFunctor, DeriveGeneric, DeriveTraversable, DerivingStrategies, DerivingVia, DuplicateRecordFields, EmptyDataDecls, FlexibleContexts, FlexibleInstances, FunctionalDependencies, GADTs, GeneralizedNewtypeDeriving, ImportQualifiedPost, LambdaCase, LiberalTypeSynonyms, MagicHash, MultiParamTypeClasses, MultiWayIf, NamedFieldPuns, NoFieldSelectors, NoImplicitPrelude, NoMonomorphismRestriction, NumericUnderscores, OverloadedRecordDot, OverloadedStrings, ParallelListComp, PatternGuards, QuasiQuotes, RankNTypes, RecordWildCards, ScopedTypeVariables, StandaloneDeriving, StrictData, TemplateHaskell, TupleSections, TypeApplications, TypeFamilies, TypeOperators, UnboxedTuples, ViewPatterns

            exposed-modules:
              ${params.rootNamespace}.Statements
              ${params.rootNamespace}.Types
              
            other-modules:
              ${params.rootNamespace}.Prelude
              ${Deps.Prelude.Text.concatMapSep
                  ("\n" ++ "    ")
                  Text
                  ( \(name : Text) ->
                      params.rootNamespace ++ ".Statements." ++ name
                  )
                  params.statementModuleNames}
              ${Deps.Prelude.Text.concatMapSep
                  ("\n" ++ "    ")
                  Text
                  (\(name : Text) -> params.rootNamespace ++ ".Types." ++ name)
                  params.customTypeNames}

            build-depends:
              aeson >=2 && <3,
              base >=4.14 && <5,
              bytestring >=0.10 && <0.13,
              containers >=0.6 && <0.9,
              hasql ^>=1.10.1,
              hasql-mapping ^>=0.1,
              scientific >=0.3 && <0.4,
              text >=1.2 && <3,
              time >=1.9 && <2,
              uuid >=1.2 && <2,
              vector >=0.12 && <0.14,
          ''
      )
