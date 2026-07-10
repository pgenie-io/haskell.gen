let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Haddock = ./Haddock.dhall

let ReexportedModule = { header : Optional Text, namespace : Text }

let Params =
      { haddock : Optional Text
      , namespace : Text
      , reexportedModules : List ReexportedModule
      }

in      Sdk.Sigs.template
          Params
          ( \(params : Params) ->
              let haddock = Haddock.run params.haddock

              let importsBlock =
                    Prelude.Text.concatMapSep
                      "\n"
                      ReexportedModule
                      ( \(module : ReexportedModule) ->
                          "import ${module.namespace}"
                      )
                      params.reexportedModules

              let exportsBlock =
                    Prelude.Text.concatMapSep
                      "\n"
                      ReexportedModule
                      ( \(module : ReexportedModule) ->
                          let haddock =
                                Prelude.Optional.fold
                                  Text
                                  module.header
                                  Text
                                  ( \(header : Text) ->
                                          "-- ** "
                                      ++  Lude.Text.prefixEachLine "-- " header
                                      ++  "\n"
                                  )
                                  ""

                          in  "${haddock}module ${module.namespace},"
                      )
                      params.reexportedModules

              in  ''
                  ${haddock}module ${params.namespace} 
                    ( ${Lude.Text.indent 4 exportsBlock}
                    )
                  where

                  ${importsBlock}
                  ''
          )
    //  { ReexportedModule }
