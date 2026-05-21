let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Templates = ../Templates/package.dhall

let Member = ./Member.dhall

let Project = Deps.Project

let Input = Project.ResultRows

let Output = Text -> { decoderExp : Text, typeDecls : Text }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        let compiledColumns =
              Deps.Typeclasses.Classes.Applicative.traverseList
                Deps.Lude.Compiled.Type
                Deps.Lude.Compiled.applicative
                Project.Member
                Member.Output
                (Member.run config)
                (Deps.Prelude.NonEmpty.toList Project.Member input.columns)

        in  Deps.Lude.Compiled.flatMap
              (List Member.Output)
              Output
              ( \(columns : List Member.Output) ->
                  Deps.Lude.Compiled.ok
                    Output
                    ( \(typeNameBase : Text) ->
                        let rowTypeName = "${typeNameBase}ResultRow"

                        let rowTypeDecl =
                                  Templates.RecordDeclaration.run
                                    { name = rowTypeName
                                    , fields =
                                        Deps.Prelude.List.map
                                          Member.Output
                                          Text
                                          ( \(column : Member.Output) ->
                                              column.fieldDeclaration
                                          )
                                          columns
                                    }
                              ++  "\n"
                              ++  "  deriving stock (Show, Eq)"

                        let rowDecoderExp =
                              ''
                              do
                                ${Deps.Lude.Text.indent
                                    2
                                    ( Deps.Prelude.Text.concatMap
                                        Member.Output
                                        ( \(column : Member.Output) ->
                                            ''
                                            ${column.fieldName} <- Decoders.column (${column.fieldDecoder})
                                            ''
                                        )
                                        columns
                                    )}pure ${rowTypeName} {..}''

                        let resolvedCardinality =
                              merge
                                { Optional =
                                  { decoderExp =
                                      "Decoders.rowMaybe ${rowDecoderExp}"
                                  , resultTypeDecl =
                                      "type ${typeNameBase}Result = Maybe ${rowTypeName}"
                                  }
                                , Single =
                                  { decoderExp =
                                      "Decoders.singleRow ${rowDecoderExp}"
                                  , resultTypeDecl =
                                      "type ${typeNameBase}Result = ${rowTypeName}"
                                  }
                                , Multiple =
                                  { decoderExp =
                                      "Decoders.rowVector ${rowDecoderExp}"
                                  , resultTypeDecl =
                                      "type ${typeNameBase}Result = Vector.Vector ${rowTypeName}"
                                  }
                                }
                                input.cardinality

                        let typeDecls =
                              ''
                              -- | Result of the statement parameterised by '${typeNameBase}'.
                              ${resolvedCardinality.resultTypeDecl}

                              -- | Row of '${typeNameBase}Result'.
                              ${rowTypeDecl}
                              ''

                        in  { decoderExp = resolvedCardinality.decoderExp
                            , typeDecls
                            }
                    )
              )
              compiledColumns

in  Algebra.module Input Output run
