let Deps = ../Deps/package.dhall

let ResolvedTarget = ../ResolvedTarget.dhall

let Templates = ../Templates/package.dhall

let Lude = Deps.Lude

let Member = ./Member.dhall

let Contract = Deps.Contract

let Input = Contract.ResultRows

let Output = Text -> { decoderExp : Text, typeDecls : Text }

let run =
      \(config : ResolvedTarget.Type) ->
      \(input : Input) ->
        let compiledColumns =
              Deps.Typeclasses.Classes.Applicative.traverseList
                Deps.Lude.Compiled.Type
                Deps.Lude.Compiled.applicative
                Contract.Member
                Member.Output
                (Member.run config)
                (Deps.Prelude.NonEmpty.toList Contract.Member input.columns)

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
                              let columnBindings =
                                    Deps.Prelude.Text.concatMapSep
                                      "\n"
                                      Member.Output
                                      ( \(column : Member.Output) ->
                                          "${column.fieldName} <- Hasql.Decoders.column (${column.fieldDecoder})"
                                      )
                                      columns

                              in  ''
                                  do
                                    ${Lude.Text.indentNonEmpty 2 columnBindings}
                                    pure ${rowTypeName} {..}''

                        let resolvedCardinality =
                              merge
                                { Optional =
                                  { decoderExp =
                                      "Hasql.Decoders.rowMaybe ${rowDecoderExp}"
                                  , resultTypeDecl =
                                      "type ${typeNameBase}Result = Maybe ${rowTypeName}"
                                  }
                                , Single =
                                  { decoderExp =
                                      "Hasql.Decoders.singleRow ${rowDecoderExp}"
                                  , resultTypeDecl =
                                      "type ${typeNameBase}Result = ${rowTypeName}"
                                  }
                                , Multiple =
                                  { decoderExp =
                                      "Hasql.Decoders.rowVector ${rowDecoderExp}"
                                  , resultTypeDecl =
                                      "type ${typeNameBase}Result = Data.Vector.Vector ${rowTypeName}"
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

in  Deps.Sdk.Sigs.Interpreter.module ResolvedTarget.Type Input Output run
