let Sdk = ../Deps/Sdk.dhall

let Deps = ../Deps/package.dhall

let Params = { namespace : List Text }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          "src/" ++ Deps.Prelude.Text.concatSep "/" params.namespace ++ ".hs"
      )
