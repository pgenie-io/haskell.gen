let Algebra = ./Algebra/package.dhall

let Params = { projectNamespace : Text }

let run =
      \(params : Params) ->
        ''
        module ${params.projectNamespace}.Prelude
          ( module Exports,
          )
        where

        import Prelude as Exports
        import Data.Functor.Contravariant as Exports (Contravariant (..), (>$<))
        import Data.UUID as Exports (UUID)
        import Data.Text as Exports (Text)
        import Data.Int as Exports (Int16, Int32, Int64)
        import Data.Word as Exports (Word16, Word32, Word64)
        import Data.Scientific as Exports (Scientific)
        import Data.ByteString as Exports (ByteString)
        import Data.Time as Exports (Day, DiffTime, TimeOfDay, TimeZone, LocalTime, UTCTime)
        import Data.Vector as Exports (Vector)
        import Hasql.PostgresqlTypes ()

        ''

in  Algebra.module Params run
