let Sdk = ../Deps/Sdk.dhall

let Prelude = ../Deps/Prelude.dhall

let Lude = ../Deps/Lude.dhall

let Params =
      { moduleNamespace : Text
      , statementsModuleNamespace : Text
      , statementSpecs : List Text
      }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          let imports =
                Prelude.Text.concatMapSep
                  "\n"
                  Text
                  ( \(statementName : Text) ->
                      "import qualified ${params.statementsModuleNamespace}.${statementName}Spec"
                  )
                  params.statementSpecs

          let subspecs =
                Prelude.Text.concatMapSep
                  "\n"
                  Text
                  ( \(statementName : Text) ->
                      "describe \"${statementName}\" ${params.statementsModuleNamespace}.${statementName}Spec.spec"
                  )
                  params.statementSpecs

          in  ''
              module ${params.moduleNamespace} (spec) where

              import qualified Hasql.Pool
              import Test.Hspec
              ${imports}

              spec :: SpecWith Hasql.Pool.Pool
              spec = parallel $ describe "Statements" $ do
                ${Lude.Text.indentNonEmpty 2 subspecs}
              ''
      )
