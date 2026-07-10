let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

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
        import Test.QuickCheck (Arbitrary (..))
        import Test.QuickCheck.Instances ()

        import qualified Data.Aeson
        import qualified Data.Vector
        import qualified Hasql.Decoders
        import qualified Hasql.Encoders
        import qualified Hasql.Mapping.IsScalar
        import qualified PostgresqlTypes
        ${if    Prelude.List.null Text params.customTypeModules
          then  ""
          else  Prelude.Text.concatMapSep
                  "\n"
                  Text
                  (\(m : Text) -> "import ${m}")
                  params.customTypeModules}

        -- |
        -- Representation of the @${params.pgTypeName}@ user-declared PostgreSQL record type.
        data ${params.typeName} = ${params.typeName}
          { ${Lude.Text.indent
                4
                ( Prelude.Text.concatSep
                    ''
                    ,
                    ''
                    params.fieldDeclarations
                )}
          }
          deriving stock (Show, Eq, Ord)

        instance Arbitrary ${params.typeName} where
          arbitrary =
            ${Lude.Text.indent
                12
                ( if    Prelude.List.null Text params.fieldNames
                  then  "pure ${params.typeName}"
                  else      "${params.typeName} <\$> "
                        ++  Prelude.Text.concatMapSep
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
                  [ ${Lude.Text.indent
                        12
                        ( Prelude.Text.concatSep
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
                  <$> ${Lude.Text.indent
                          10
                          ( Prelude.Text.concatMapSep
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

in  Sdk.Sigs.template Params run
