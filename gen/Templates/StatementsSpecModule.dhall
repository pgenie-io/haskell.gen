let Algebra = ./Algebra/package.dhall

let Prelude = ../Deps/Prelude.dhall

let Lude = ../Deps/Lude.dhall

let Params =
      { moduleNamespace : Text
      , statementsModuleNamespace : Text
      , statementSpecs : List Text
      }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let imports =
                Prelude.Text.concatMapSep
                  "\n"
                  Text
                  ( \(statementName : Text) ->
                      "import qualified ${params.statementsModuleNamespace}.${statementName}Spec as ${statementName}Spec"
                  )
                  params.statementSpecs

          let subspecs =
                Prelude.Text.concatMapSep
                  "\n"
                  Text
                  ( \(statementName : Text) ->
                      "describe \"${statementName}\" ${statementName}Spec.spec"
                  )
                  params.statementSpecs

          in  ''
              module ${params.moduleNamespace} (spec) where

              import qualified Hasql.Pool as Pool
              import Test.Hspec
              ${imports}

              spec :: SpecWith Pool.Pool
              spec = parallel $ describe "Statements" $ do
                ${Lude.Text.indentNonEmpty 2 subspecs}
              ''
      )
