let Contract = ../Deps/Contract.dhall

let Lude = ../Deps/Lude.dhall

let Sdk = ../Deps/Sdk.dhall

let Config = { rootNamespace : List Text }

let Input = Contract.Primitive

let Output =
      { sig : Text
      , encoderExp : Text
      , decoderExp : Text
      , testArbitraryGen : Text
      }

let defaultTestArbitraryGen = "arbitrary"

let fromWrapped = \(converter : Text) -> "(${converter} <\$> arbitrary)"

let unsupportedType =
      \(type : Text) -> Lude.Compiled.report Output [ type ] "Unsupported type"

let std =
      \(sig : Text) ->
      \(codecName : Text) ->
        Lude.Compiled.ok
          Output
          { sig
          , encoderExp = "Hasql.Encoders.${codecName}"
          , decoderExp = "Hasql.Decoders.${codecName}"
          , testArbitraryGen = defaultTestArbitraryGen
          }

let fromWrappedGen =
      \(sig : Text) ->
      \(codecName : Text) ->
      \(converter : Text) ->
        Lude.Compiled.ok
          Output
          { sig
          , encoderExp = "Hasql.Encoders.${codecName}"
          , decoderExp = "Hasql.Decoders.${codecName}"
          , testArbitraryGen = fromWrapped converter
          }

let isScalar =
      \(sig : Text) ->
        Lude.Compiled.ok
          Output
          { sig
          , encoderExp = "Hasql.Mapping.IsScalar.encoder"
          , decoderExp = "Hasql.Mapping.IsScalar.decoder"
          , testArbitraryGen = defaultTestArbitraryGen
          }

let run =
      \(config : Config) ->
      \(input : Input) ->
        merge
          { Bit = isScalar "PostgresqlTypes.Bit 1"
          , Bool = std "Bool" "bool"
          , Box = isScalar "PostgresqlTypes.Box"
          , Bpchar = isScalar "PostgresqlTypes.Bpchar 0"
          , Bytea =
              fromWrappedGen
                "ByteString"
                "bytea"
                "PostgresqlTypes.Bytea.toByteString"
          , Char = isScalar "PostgresqlTypes.Char"
          , Circle = isScalar "PostgresqlTypes.Circle"
          , Cidr = isScalar "PostgresqlTypes.Cidr"
          , Citext = unsupportedType "citext"
          , Date = isScalar "PostgresqlTypes.Date"
          , Datemultirange =
              isScalar "PostgresqlTypes.Multirange PostgresqlTypes.Date"
          , Daterange = isScalar "PostgresqlTypes.Range PostgresqlTypes.Date"
          , Float4 =
              fromWrappedGen "Float" "float4" "PostgresqlTypes.Float4.toFloat"
          , Float8 =
              fromWrappedGen "Double" "float8" "PostgresqlTypes.Float8.toDouble"
          , Hstore = isScalar "PostgresqlTypes.Hstore"
          , Inet = isScalar "PostgresqlTypes.Inet"
          , Int2 = fromWrappedGen "Int16" "int2" "PostgresqlTypes.Int2.toInt16"
          , Int4 = fromWrappedGen "Int32" "int4" "PostgresqlTypes.Int4.toInt32"
          , Int4multirange =
              isScalar "PostgresqlTypes.Multirange PostgresqlTypes.Int4"
          , Int4range = isScalar "PostgresqlTypes.Range PostgresqlTypes.Int4"
          , Int8 = fromWrappedGen "Int64" "int8" "PostgresqlTypes.Int8.toInt64"
          , Int8multirange =
              isScalar "PostgresqlTypes.Multirange PostgresqlTypes.Int8"
          , Int8range = isScalar "PostgresqlTypes.Range PostgresqlTypes.Int8"
          , Interval = isScalar "PostgresqlTypes.Interval"
          , Json = isScalar "PostgresqlTypes.Json"
          , Jsonb = isScalar "PostgresqlTypes.Jsonb"
          , Line = isScalar "PostgresqlTypes.Line"
          , Lseg = isScalar "PostgresqlTypes.Lseg"
          , Macaddr = isScalar "PostgresqlTypes.Macaddr"
          , Macaddr8 = isScalar "PostgresqlTypes.Macaddr8"
          , Money = isScalar "PostgresqlTypes.Money"
          , Name = unsupportedType "name"
          , Numeric =
              Lude.Compiled.ok
                Output
                { sig = "Scientific"
                , encoderExp = "Hasql.Mapping.IsScalar.encoder"
                , decoderExp = "Hasql.Mapping.IsScalar.decoder"
                , testArbitraryGen = defaultTestArbitraryGen
                }
          , Nummultirange =
              isScalar
                "PostgresqlTypes.Multirange (PostgresqlTypes.Numeric 0 0)"
          , Numrange =
              isScalar "PostgresqlTypes.Range (PostgresqlTypes.Numeric 0 0)"
          , Oid = isScalar "PostgresqlTypes.Oid"
          , Path = isScalar "PostgresqlTypes.Path"
          , PgLsn = unsupportedType "pg_lsn"
          , PgSnapshot = unsupportedType "pg_snapshot"
          , Point = isScalar "PostgresqlTypes.Point"
          , Polygon = isScalar "PostgresqlTypes.Polygon"
          , Text = fromWrappedGen "Text" "text" "PostgresqlTypes.Text.toText"
          , Time = isScalar "PostgresqlTypes.Time"
          , Timestamp = isScalar "PostgresqlTypes.Timestamp"
          , Timestamptz = isScalar "PostgresqlTypes.Timestamptz"
          , Timetz = isScalar "PostgresqlTypes.Timetz"
          , Tsmultirange =
              isScalar "PostgresqlTypes.Multirange PostgresqlTypes.Timestamp"
          , Tsquery = unsupportedType "tsquery"
          , Tsrange = isScalar "PostgresqlTypes.Range PostgresqlTypes.Timestamp"
          , Tstzmultirange =
              isScalar "PostgresqlTypes.Multirange PostgresqlTypes.Timestamptz"
          , Tstzrange =
              isScalar "PostgresqlTypes.Range PostgresqlTypes.Timestamptz"
          , Tsvector = isScalar "PostgresqlTypes.Tsvector"
          , Uuid = fromWrappedGen "UUID" "uuid" "PostgresqlTypes.Uuid.toUUID"
          , Varbit = isScalar "PostgresqlTypes.Varbit 0"
          , Varchar = isScalar "PostgresqlTypes.Varchar 0"
          , Xml = unsupportedType "xml"
          , Box2D = unsupportedType "box2d"
          , Box3D = unsupportedType "box3d"
          , Geography = unsupportedType "geography"
          , Geometry = unsupportedType "geometry"
          , Ltree = unsupportedType "ltree"
          }
          input

in  Sdk.Sigs.interpreter Config Input Output run
