let Deps = ../Deps/package.dhall

let Algebra = ./Algebra/package.dhall

let Project = Deps.Project

let Input = Project.Primitive

let Output =
      { sig : Text
      , encoderExp : Text
      , decoderExp : Text
      , testDefaultLiteral : Text
      }

let unsupportedType =
      \(type : Text) ->
        Deps.Lude.Compiled.report Output [ type ] "Unsupported type"

let std =
      \(sig : Text) ->
      \(codecName : Text) ->
      \(testDefaultLiteral : Text) ->
        Deps.Lude.Compiled.ok
          Output
          { sig
          , encoderExp = "Encoders.${codecName}"
          , decoderExp = "Decoders.${codecName}"
          , testDefaultLiteral
          }

let isScalar =
      \(sig : Text) ->
      \(testDefaultLiteral : Text) ->
        Deps.Lude.Compiled.ok
          Output
          { sig
          , encoderExp = "IsScalar.encoder"
          , decoderExp = "IsScalar.decoder"
          , testDefaultLiteral
          }

let run =
      \(config : Algebra.Config) ->
      \(input : Input) ->
        merge
          { Bit = isScalar "Pt.Bit 1" "\"1\""
          , Bool = std "Bool" "bool" "True"
          , Box = isScalar "Pt.Box" "\"(0,0),(3,7)\""
          , Bpchar = isScalar "Pt.Bpchar 0" "\"ABC\""
          , Bytea = std "ByteString" "bytea" "mempty"
          , Char = isScalar "Pt.Char" "\"Z\""
          , Circle = isScalar "Pt.Circle" "\"<(1.5,2.5),3>\""
          , Cidr = isScalar "Pt.Cidr" "\"10.42.0.0/16\""
          , Citext = unsupportedType "citext"
          , Date = isScalar "Pt.Date" "\"2000-01-01\""
          , Datemultirange = isScalar "Pt.Multirange Pt.Date" "\"{}\""
          , Daterange =
              isScalar "Pt.Range Pt.Date" "\"[2000-01-01,2000-01-02)\""
          , Float4 = std "Float" "float4" "3.14"
          , Float8 = std "Double" "float8" "42.5"
          , Hstore = isScalar "Pt.Hstore" "\"\\\"genre\\\"=>\\\"ambient\\\"\""
          , Inet = isScalar "Pt.Inet" "\"192.168.10.4/32\""
          , Int2 = std "Int16" "int2" "7"
          , Int4 = std "Int32" "int4" "42"
          , Int4multirange = isScalar "Pt.Multirange Pt.Int4" "\"{}\""
          , Int4range = isScalar "Pt.Range Pt.Int4" "\"[10,20)\""
          , Int8 = std "Int64" "int8" "4242"
          , Int8multirange = isScalar "Pt.Multirange Pt.Int8" "\"{}\""
          , Int8range = isScalar "Pt.Range Pt.Int8" "\"[100,200)\""
          , Interval = isScalar "Pt.Interval" "\"01:23:45\""
          , Json = isScalar "Pt.Json" "\"{\\\"kind\\\":\\\"demo\\\"}\""
          , Jsonb = isScalar "Pt.Jsonb" "\"{\\\"kind\\\":\\\"demo\\\"}\""
          , Line = isScalar "Pt.Line" "\"{1,0,-1}\""
          , Lseg = isScalar "Pt.Lseg" "\"[(1,2),(3,4)]\""
          , Macaddr = isScalar "Pt.Macaddr" "\"08:00:2b:01:02:03\""
          , Macaddr8 = isScalar "Pt.Macaddr8" "\"08:00:2b:01:02:03:04:05\""
          , Money = isScalar "Pt.Money" "\"\$12.34\""
          , Name = unsupportedType "name"
          , Numeric = isScalar "Pt.Numeric 0 0" "\"123.45\""
          , Nummultirange = isScalar "Pt.Multirange (Pt.Numeric 0 0)" "\"{}\""
          , Numrange = isScalar "Pt.Range (Pt.Numeric 0 0)" "\"[1.1,2.2)\""
          , Oid = isScalar "Pt.Oid" "\"42\""
          , Path = isScalar "Pt.Path" "\"[(0,0),(1,2),(2,3)]\""
          , PgLsn = unsupportedType "pg_lsn"
          , PgSnapshot = unsupportedType "pg_snapshot"
          , Point = isScalar "Pt.Point" "\"(4,5)\""
          , Polygon = isScalar "Pt.Polygon" "\"((0,0),(2,0),(1,3))\""
          , Text = std "Text" "text" "mempty"
          , Time = isScalar "Pt.Time" "\"12:34:56\""
          , Timestamp = isScalar "Pt.Timestamp" "\"2000-01-01 12:34:56\""
          , Timestamptz = isScalar "Pt.Timestamptz" "\"2000-01-01 12:34:56+00\""
          , Timetz = isScalar "Pt.Timetz" "\"12:34:56+00\""
          , Tsmultirange = isScalar "Pt.Multirange Pt.Timestamp" "\"{}\""
          , Tsquery = unsupportedType "tsquery"
          , Tsrange =
              isScalar
                "Pt.Range Pt.Timestamp"
                "\"[2000-01-01 00:00:00,2000-01-02 00:00:00)\""
          , Tstzmultirange = isScalar "Pt.Multirange Pt.Timestamptz" "\"{}\""
          , Tstzrange =
              isScalar
                "Pt.Range Pt.Timestamptz"
                "\"[2000-01-01 00:00:00+00,2000-01-02 00:00:00+00)\""
          , Tsvector = isScalar "Pt.Tsvector" "\"'demo':1\""
          , Uuid = std "UUID" "uuid" "Data.UUID.nil"
          , Varbit = isScalar "Pt.Varbit 0" "\"\""
          , Varchar = isScalar "Pt.Varchar 0" "\"\""
          , Xml = unsupportedType "xml"
          , Box2D = unsupportedType "box2d"
          , Box3D = unsupportedType "box3d"
          , Geography = unsupportedType "geography"
          , Geometry = unsupportedType "geometry"
          , Ltree = unsupportedType "ltree"
          }
          input

in  Algebra.module Input Output run
