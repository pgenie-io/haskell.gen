let Sdk = ../Deps/Sdk.dhall

let Lude = ../Deps/Lude.dhall

let Prelude = ../Deps/Prelude.dhall

let Params = { name : Text, fields : List Text }

in  Sdk.Sigs.template
      Params
      ( \(params : Params) ->
          let length = List/length Text params.fields

          in  if    Prelude.Natural.greaterThan length 1
              then  ''
                    data ${params.name} = ${params.name}
                      { ${Lude.Text.indent
                            4
                            ( Prelude.Text.concatSep
                                ''
                                ,
                                ''
                                params.fields
                            )}
                      }''
              else  merge
                      { None = "data ${params.name} = ${params.name}"
                      , Some =
                          \(field : Text) ->
                            ''
                            newtype ${params.name} = ${params.name}
                              { ${Lude.Text.indent 4 field}
                              }''
                      }
                      (List/head Text params.fields)
      )
