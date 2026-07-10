let Sdk = ../Deps/Sdk.dhall

let Deps = ../Deps/package.dhall

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
                    Deps.Prelude.Text.concatMapSep
                      "\n"
                      ReexportedModule
                      ( \(module : ReexportedModule) ->
                          "import ${module.namespace}"
                      )
                      params.reexportedModules

              let exportsBlock =
                    Deps.Prelude.Text.concatMapSep
                      "\n"
                      ReexportedModule
                      ( \(module : ReexportedModule) ->
                          let haddock =
                                Deps.Prelude.Optional.fold
                                  Text
                                  module.header
                                  Text
                                  ( \(header : Text) ->
                                          "-- ** "
                                      ++  Deps.Lude.Text.prefixEachLine
                                            "-- "
                                            header
                                      ++  "\n"
                                  )
                                  ""

                          in  "${haddock}module ${module.namespace},"
                      )
                      params.reexportedModules

              in  ''
                  ${haddock}module ${params.namespace} 
                    ( ${Deps.Lude.Text.indent 4 exportsBlock}
                    )
                  where

                  ${importsBlock}
                  ''
          )
    //  { ReexportedModule }
