let Sdk = ../Deps/Sdk.dhall

let Deps = ../Deps/package.dhall

let RecordDeclaration = ./RecordDeclaration.dhall

let Params =
      { queryName : Text
      , sqlForDocs : Text
      , srcPath : Text
      , typeName : Text
      , fields : List Text
      }

in  Sdk.Sigs.Template.module
      Params
      ( \(params : Params) ->
          ''
          -- |
          -- Parameters for the @${params.queryName}@ query.
          --
          -- ==== SQL Template
          --
          -- > ${Deps.Lude.Text.prefixEachLine "-- > " params.sqlForDocs}
          --
          -- ==== Source Path
          --
          -- > ${params.srcPath}
          --
          ${RecordDeclaration.run
              { name = params.typeName, fields = params.fields }}
            deriving stock (Eq, Show)
          ''
      )
