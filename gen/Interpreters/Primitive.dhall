let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Input = Deps.Sdk.Project.Primitive

let Output = { sig : Text, encoderExp : Text, decoderExp : Text }

let unsupportedType =
      \(type : Text) ->
        Deps.Sdk.Compiled.report Output [ type ] "Unsupported type"

let std =
      \(sig : Text) ->
      \(codecName : Text) ->
        Deps.Sdk.Compiled.ok
          Output
          { sig
          , encoderExp = "Encoders.${codecName}"
          , decoderExp = "Decoders.${codecName}"
          }

let isScalar =
      \(sig : Text) ->
        Deps.Sdk.Compiled.ok
          Output
          { sig
          , encoderExp = "IsScalar.encoder"
          , decoderExp = "IsScalar.decoder"
          }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Bit = isScalar "Bit"
          , Bool = std "Bool" "bool"
          , Box = isScalar "Box"
          , Bpchar = std "Text" "bpchar"
          , Bytea = std "ByteString" "bytea"
          , Char = isScalar "Pt.Char"
          , Circle = isScalar "Pt.Circle"
          , Cidr = isScalar "Pt.Cidr"
          , Citext = std "Text" "citext"
          , Date = isScalar "Pt.Date"
          , Datemultirange = isScalar "Pt.Multirange Pt.Date"
          , Daterange = isScalar "Pt.Range Pt.Date"
          , Float4 = std "Float" "float4"
          , Float8 = std "Double" "float8"
          , Hstore = isScalar "Pt.Hstore"
          , Inet = isScalar "Pt.Inet"
          , Int2 = std "Int16" "int2"
          , Int4 = std "Int32" "int4"
          , Int4multirange = isScalar "Pt.Multirange Pt.Int4"
          , Int4range = isScalar "Pt.Range Pt.Int4"
          , Int8 = std "Int64" "int8"
          , Int8multirange = isScalar "Pt.Multirange Pt.Int8"
          , Int8range = isScalar "Pt.Range Pt.Int8"
          , Interval = isScalar "Pt.Interval"
          , Json = isScalar "Pt.Json"
          , Jsonb = isScalar "Pt.Jsonb"
          , Line = isScalar "Pt.Line"
          , Lseg = isScalar "Pt.Lseg"
          , Macaddr = isScalar "Pt.Macaddr"
          , Macaddr8 = isScalar "Pt.Macaddr8"
          , Money = isScalar "Pt.Money"
          , Name = std "Text" "name"
          , Numeric = std "Scientific" "numeric"
          , Nummultirange = isScalar "Pt.Multirange Pt.Numeric"
          , Numrange = isScalar "Pt.Range Pt.Numeric"
          , Oid = isScalar "Pt.Oid"
          , Path = isScalar "Pt.Path"
          , PgLsn = unsupportedType "pg_lsn"
          , PgSnapshot = unsupportedType "pg_snapshot"
          , Point = isScalar "Pt.Point"
          , Polygon = isScalar "Pt.Polygon"
          , Text = std "Text" "text"
          , Time = isScalar "Pt.Time"
          , Timestamp = isScalar "Pt.Timestamp"
          , Timestamptz = isScalar "Pt.Timestamptz"
          , Timetz = isScalar "Pt.Timetz"
          , Tsmultirange = isScalar "Pt.Multirange Pt.Timestamp"
          , Tsquery = unsupportedType "tsquery"
          , Tsrange = isScalar "Pt.Range Pt.Timestamp"
          , Tstzmultirange = isScalar "Pt.Multirange Pt.Timestamptz"
          , Tstzrange = isScalar "Pt.Range Pt.Timestamptz"
          , Tsvector = isScalar "Pt.Tsvector"
          , Uuid = std "UUID" "uuid"
          , Varbit = isScalar "Pt.Varbit"
          , Varchar = std "Text" "varchar"
          , Xml = unsupportedType "xml"
          }
          input

in  Algebra.module Input Output run
