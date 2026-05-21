let Algebra = ./Algebra/package.dhall

let Deps = ../Deps/package.dhall

let Params = { name : Text, fields : List Text }

in  Algebra.module
      Params
      ( \(params : Params) ->
          let length = List/length Text params.fields

          in  if    Deps.Prelude.Natural.greaterThan length 1
              then  ''
                    data ${params.name} = ${params.name}
                      { ${Deps.Lude.Text.indent
                            4
                            ( Deps.Prelude.Text.concatSep
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
                              { ${Deps.Lude.Text.indent 4 field}
                              }''
                      }
                      (List/head Text params.fields)
      )
