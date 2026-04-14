# haskell.gen

A [pGenie](https://github.com/pgenie-io/pgenie) plugin that generates type-safe Haskell bindings for PostgreSQL using the [Hasql](https://hackage.haskell.org/package/hasql) library.

## What it generates

For each pGenie project the plugin produces a self-contained Haskell package containing:

- **A `.cabal` file** – a ready-to-build library with all required dependencies declared.
- **`<Namespace>.Statements.*`** – one module per SQL query. Each module contains:
  - A parameter record type (e.g. `InsertAlbum`) with a field per query parameter.
  - A result type alias (e.g. `InsertAlbumResult`) with a corresponding row type.
  - An `IsStatement` instance that holds the compiled `Statement` value, including the SQL text, encoder, and decoder.
- **`<Namespace>.Statements`** – a module re-exporting all statement modules. All names are prefixed with the statement name, so conflicts are impossible.
- **`<Namespace>.Types.*`** – one module per custom PostgreSQL type. Each module contains a Haskell type and its `IsScalar` instance for encoding/decoding:
  - **Enums** → `data` declarations with pattern-matched codec.
  - **Composite types** → record declarations with composite codec.
- **`<Namespace>.Types`** – a module re-exporting all the type modules.

All statements are compatible with the `hasql-mapping` execution API and can also be used directly via `hasql`.

## Using the plugin in a pGenie project

Add the plugin to your pGenie project configuration file (`project1.pgn.yaml`):

```yaml
space: my_space
name: music_catalogue
version: 1.0.0
artifacts:
  # Here
  hasql: https://raw.githubusercontent.com/pgenie-io/haskell.gen/v0.2.2/gen/Gen.dhall
```

Run the code generator:

```bash
pgn generate
```

The generated package will be placed in the `artifacts/hasql` as configured in your project. Add it to your Haskell project's `cabal.project` or `stack.yaml` as a local package.

## Supported PostgreSQL types

Scalar types can appear as plain values, as nullable values (`Maybe a`), or as arrays of any dimensionality (`Vector a`, `Vector (Vector a)`, …) with controllable nullability of the elements of arrays as well as of arrays themselves.

| PostgreSQL type        | Haskell type                                    | Notes                      |
|------------------------|-------------------------------------------------|----------------------------|
| `bit`                  | `Pt.Bit 1`                                      | postgresql-types           |
| `bool`                 | `Bool`                                          |                            |
| `box`                  | `Pt.Box`                                        | postgresql-types           |
| `bpchar` / `char(n)`   | `Text`                                          |                            |
| `bytea`                | `ByteString`                                    |                            |
| `char`                 | `Pt.Char`                                       | postgresql-types           |
| `cidr`                 | `Pt.Cidr`                                       | postgresql-types           |
| `circle`               | `Pt.Circle`                                     | postgresql-types           |
| `citext`               | `Text`                                          |                            |
| `date`                 | `Pt.Date`                                       | postgresql-types           |
| `datemultirange`       | `Pt.Multirange Pt.Date`                         | postgresql-types           |
| `daterange`            | `Pt.Range Pt.Date`                              | postgresql-types           |
| `float4`               | `Float`                                         |                            |
| `float8`               | `Double`                                        |                            |
| `hstore`               | `Pt.Hstore`                                     | postgresql-types           |
| `inet`                 | `Pt.Inet`                                       | postgresql-types           |
| `int2`                 | `Int16`                                         |                            |
| `int4`                 | `Int32`                                         |                            |
| `int4multirange`       | `Pt.Multirange Pt.Int4`                         | postgresql-types           |
| `int4range`            | `Pt.Range Pt.Int4`                              | postgresql-types           |
| `int8`                 | `Int64`                                         |                            |
| `int8multirange`       | `Pt.Multirange Pt.Int8`                         | postgresql-types           |
| `int8range`            | `Pt.Range Pt.Int8`                              | postgresql-types           |
| `interval`             | `Pt.Interval`                                   | postgresql-types           |
| `json`                 | `Pt.Json`                                       | postgresql-types           |
| `jsonb`                | `Pt.Jsonb`                                      | postgresql-types           |
| `line`                 | `Pt.Line`                                       | postgresql-types           |
| `lseg`                 | `Pt.Lseg`                                       | postgresql-types           |
| `macaddr`              | `Pt.Macaddr`                                    | postgresql-types           |
| `macaddr8`             | `Pt.Macaddr8`                                   | postgresql-types           |
| `money`                | `Pt.Money`                                      | postgresql-types           |
| `name`                 | `Text`                                          |                            |
| `numeric`              | `Pt.Numeric 0 0`                                | postgresql-types           |
| `nummultirange`        | `Pt.Multirange (Pt.Numeric 0 0)`                | postgresql-types           |
| `numrange`             | `Pt.Range (Pt.Numeric 0 0)`                     | postgresql-types           |
| `oid`                  | `Pt.Oid`                                        | postgresql-types           |
| `path`                 | `Pt.Path`                                       | postgresql-types           |
| `point`                | `Pt.Point`                                      | postgresql-types           |
| `polygon`              | `Pt.Polygon`                                    | postgresql-types           |
| `text`                 | `Text`                                          |                            |
| `time`                 | `Pt.Time`                                       | postgresql-types           |
| `timestamp`            | `Pt.Timestamp`                                  | postgresql-types           |
| `timestamptz`          | `Pt.Timestamptz`                                | postgresql-types           |
| `timetz`               | `Pt.Timetz`                                     | postgresql-types           |
| `tsmultirange`         | `Pt.Multirange Pt.Timestamp`                    | postgresql-types           |
| `tsrange`              | `Pt.Range Pt.Timestamp`                         | postgresql-types           |
| `tstzmultirange`       | `Pt.Multirange Pt.Timestamptz`                  | postgresql-types           |
| `tstzrange`            | `Pt.Range Pt.Timestamptz`                       | postgresql-types           |
| `tsvector`             | `Pt.Tsvector`                                   | postgresql-types           |
| `uuid`                 | `UUID`                                          |                            |
| `varbit`               | `Pt.Varbit 0`                                   | postgresql-types           |
| `varchar`              | `Text`                                          |                            |

Types marked **postgresql-types** use the [`postgresql-types`](https://hackage.haskell.org/package/postgresql-types) package for their Haskell representation. The `Pt.*` wrappers used for date/time, range, multirange, inet, and other PostgreSQL-specific scalars also come from that package, with codec instances supplied by [`hasql-postgresql-types`](https://hackage.haskell.org/package/hasql-postgresql-types).

Default-length and unconstrained PostgreSQL types are mapped to concrete Haskell representations where PostgreSQL defines an implicit default. For example, bare `bit` is treated as `bit(1)`, and unconstrained `numeric` is rendered as `Pt.Numeric 0 0` per the `postgresql-types` convention.

The following types are currently **not supported**: `pg_lsn`, `pg_snapshot`, `tsquery`, `xml`.

User-defined **enum** and **composite** types are also supported and generate corresponding Haskell types with `IsScalar` instances.

## Integrating generated code into a Haskell project

Add the generated package to your `cabal.project`:

```cabal
packages: .

source-repository-package
  type: git
  location: https://github.com/your-org/your-db-repo
  tag: 3248faaa706872e0fe532036aa011edd2eb9d342
  subdir: artifacts/hasql
```

Declare the dependency in your own `.cabal` file:

```cabal
build-depends:
  my-space-music-catalogue,
  hasql ^>=1.10.3,
  hasql-mapping ^>=0.1,
```

Execute statements via `Hasql.Session`:

```haskell
import qualified Hasql.Mapping.IsStatement as IsStatement
import qualified Hasql.Session as Session
import qualified Hasql.Connection as Connection
import qualified MySpace.MusicCatalogue.Statements as Statements
import qualified MySpace.MusicCatalogue.Types as Types

run :: Connection.Connection -> IO ()
run conn = do
  -- Execute a query that returns multiple rows
  result <-
    Connection.use conn $
      runStatementByParams
        Statements.SelectAlbumByName
          { name = Just "Rumours"
          }

  case result of
    Left err  -> putStrLn ("Query failed: " <> show err)
    Right rows -> mapM_ print rows

  -- Execute an insert that returns the new row id
  result2 <-
    Connection.use conn $
      runStatementByParams
        Statements.InsertAlbum
          { name = "Rumours",
            released = read "1977-02-04",
            format = Types.VinylAlbumFormat,
            recording =
              Statements.RecordingInfo
                { studioName = Just "Sound Factory",
                  city = Just "Los Angeles",
                  country = Just "US",
                  recordedDate = Nothing
                }
          }

  case result2 of
    Left err -> putStrLn ("Insert failed: " <> show err)
    Right InsertAlbumResultRow { id } -> putStrLn ("Inserted id: " <> show id)

runStatementByParams ::
  (IsStatement.IsStatement params) =>
  params ->
  Session.Session (IsStatement.Result params)
runStatementByParams params =
  Session.statement params IsStatement.statement
```

As you can see, thanks to the `IsStatement` instances dealing with the generated code is just about calling `runStatementByParams` on the generated data structures.
