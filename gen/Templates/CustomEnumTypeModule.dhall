let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Variant = { name : Text, pgValue : Text }

let Params =
      { preludeModuleName : Text
      , moduleName : Text
      , typeName : Text
      , pgSchema : Text
      , pgTypeName : Text
      , variants : List Variant
      }

let run =
      \(params : Params) ->
        ''
        module ${params.moduleName} where

        import ${params.preludeModuleName}
        import Test.QuickCheck (Arbitrary (..), elements)
        import Test.QuickCheck.Instances ()

        import qualified Hasql.Decoders
        import qualified Hasql.Encoders
        import qualified Hasql.Mapping.IsScalar

        -- |
        -- Representation of the @${params.pgTypeName}@ user-declared PostgreSQL enumeration type.
        data ${params.typeName}
          = ${Deps.Lude.Text.indent
                2
                ( Deps.Prelude.Text.concatMapSep
                    ''

                    | ''
                    Variant
                    ( \(variant : Variant) ->
                        ''
                        -- | Corresponds to the PostgreSQL enum variant @${variant.pgValue}@.
                          ${variant.name}${params.typeName}''
                    )
                    params.variants
                )}
          deriving stock (Show, Eq, Ord, Enum, Bounded)

        instance Arbitrary ${params.typeName} where
          arbitrary =
            elements
              [ ${Deps.Lude.Text.indent
                    8
                    ( Deps.Prelude.Text.concatMapSep
                        ''
                        ,
                        ''
                        Variant
                        ( \(variant : Variant) ->
                            "${variant.name}${params.typeName}"
                        )
                        params.variants
                    )}
              ]

        instance Hasql.Mapping.IsScalar.IsScalar ${params.typeName} where
          encoder =
            Hasql.Encoders.enum
              (Just "${params.pgSchema}")
              "${params.pgTypeName}"
              ( \case
                  ${Deps.Lude.Text.indent
                      10
                      ( Deps.Prelude.Text.concatMapSep
                          "\n"
                          Variant
                          ( \(variant : Variant) ->
                              "${variant.name}${params.typeName} -> \"${variant.pgValue}\""
                          )
                          params.variants
                      )}
              )
          
          decoder =
            Hasql.Decoders.enum
              (Just "${params.pgSchema}")
              "${params.pgTypeName}"
              ( \case
                  ${Deps.Lude.Text.indent
                      10
                      ( Deps.Prelude.Text.concatMapSep
                          "\n"
                          Variant
                          ( \(variant : Variant) ->
                              "\"${variant.pgValue}\" -> Just ${variant.name}${params.typeName}"
                          )
                          params.variants
                      )}
                  _ -> Nothing
              )
        ''

in  { Params, Variant, run }
