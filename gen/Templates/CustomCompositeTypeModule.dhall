let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params =
      { preludeModuleName : Text
      , moduleName : Text
      , typeName : Text
      , pgSchema : Text
      , pgTypeName : Text
      , fieldNames : List Text
      , fieldDeclarations : List Text
      , fieldEncoderExps : List Text
      , fieldDecoderExps : List Text
      , customTypeModules : List Text
      }

let run =
      \(params : Params) ->
        ''
        module ${params.moduleName} where

        import ${params.preludeModuleName}
        import qualified Data.Aeson
        import qualified Data.Vector
        import qualified Hasql.Decoders
        import qualified Hasql.Encoders
        import qualified Hasql.Mapping.IsScalar
        import qualified PostgresqlTypes
        import Test.QuickCheck (Arbitrary (..))
        import Test.QuickCheck.Instances ()
        ${if    Deps.Prelude.List.null Text params.customTypeModules
          then  ""
          else  Deps.Prelude.Text.concatMapSep
                  "\n"
                  Text
                  (\(m : Text) -> "import ${m}")
                  params.customTypeModules}

        -- |
        -- Representation of the @${params.pgTypeName}@ user-declared PostgreSQL record type.
        data ${params.typeName} = ${params.typeName}
          { ${Deps.Lude.Text.indent
                4
                ( Deps.Prelude.Text.concatSep
                    ''
                    ,
                    ''
                    params.fieldDeclarations
                )}
          }
          deriving stock (Show, Eq, Ord)

        instance Arbitrary ${params.typeName} where
          arbitrary =
            ${Deps.Lude.Text.indent
                12
                ( if    Deps.Prelude.List.null Text params.fieldNames
                  then  "pure ${params.typeName}"
                  else      "${params.typeName} <\$> "
                        ++  Deps.Prelude.Text.concatMapSep
                              " <*> "
                              Text
                              (\(_ : Text) -> "arbitrary")
                              params.fieldNames
                )}

        instance Hasql.Mapping.IsScalar.IsScalar ${params.typeName} where
          encoder =
            Hasql.Encoders.composite
              (Just "${params.pgSchema}")
              "${params.pgTypeName}"
              ( mconcat
                  [ ${Deps.Lude.Text.indent
                        12
                        ( Deps.Prelude.Text.concatSep
                            ''
                            ,
                            ''
                            params.fieldEncoderExps
                        )}
                  ]
              )
          
          decoder =
            Hasql.Decoders.composite
              (Just "${params.pgSchema}")
              "${params.pgTypeName}"
              ( ${params.typeName}
                  <$> ${Deps.Lude.Text.indent
                          10
                          ( Deps.Prelude.Text.concatMapSep
                              ''

                              <*> ''
                              Text
                              ( \(field : Text) ->
                                  "Hasql.Decoders.field (${field})"
                              )
                              params.fieldDecoderExps
                          )}
              )
        ''

in  Algebra.module Params run
