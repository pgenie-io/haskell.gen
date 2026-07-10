let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Params = { namespace : List Text }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          "src/" ++ Prelude.Text.concatSep "/" params.namespace ++ ".hs"
      )
