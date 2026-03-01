let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params =
      { preludeModuleName : Text
      , moduleName : Text
      , typeName : Text
      , pgSchema : Text
      , pgTypeName : Text
      , fieldDeclarations : List Text
      , fieldEncoderExps : List Text
      , fieldDecoderExps : List Text
      }

let run =
      \(params : Params) ->
        ''
        module ${params.moduleName} where

        import ${params.preludeModuleName}
        import qualified Data.Aeson as Aeson
        import qualified Data.Vector as Vector
        import qualified Hasql.Decoders as Decoders
        import qualified Hasql.Encoders as Encoders
        import qualified Hasql.Mapping as Mapping

        -- |
        -- Representation of the @${params.pgTypeName}@ user-declared PostgreSQL record type.
        data ${params.typeName} = ${params.typeName}
          { ${Deps.Lude.Extensions.Text.indent
                4
                ( Deps.Prelude.Text.concatSep
                    ''
                    ,
                    ''
                    params.fieldDeclarations
                )}
          }
          deriving stock (Show, Eq, Ord)

        instance Mapping.IsScalar ${params.typeName} where
          scalarEncoder =
            Encoders.composite
              (Just "${params.pgSchema}")
              "${params.pgTypeName}"
              ( mconcat
                  [ ${Deps.Lude.Extensions.Text.indent
                        12
                        ( Deps.Prelude.Text.concatSep
                            ''
                            ,
                            ''
                            params.fieldEncoderExps
                        )}
                  ]
              )
          
          scalarDecoder =
            Decoders.composite
              (Just "${params.pgSchema}")
              "${params.pgTypeName}"
              ( ${params.typeName}
                  <$> ${Deps.Lude.Extensions.Text.indent
                          10
                          ( Deps.Prelude.Text.concatMapSep
                              ''

                              <*> ''
                              Text
                              (\(field : Text) -> "Decoders.field (${field})")
                              params.fieldDecoderExps
                          )}
              )
          
        ''

in  Algebra.module Params run
