module Demo.MusicCatalogue.Types.TrackMetadata where

import Demo.MusicCatalogue.Prelude
import qualified Data.Aeson as Aeson
import qualified Data.Vector as Vector
import qualified Hasql.Decoders as Decoders
import qualified Hasql.Encoders as Encoders
import qualified Hasql.Mapping as Mapping

-- |
-- Representation of the @track_metadata@ user-declared PostgreSQL record type.
data TrackMetadata = TrackMetadata
  { -- | Maps to @title@.
    title :: Text,
    -- | Maps to @metadata@.
    metadata :: Maybe (Vector (Maybe Aeson.Value)),
    -- | Maps to @created_at@.
    createdAt :: LocalTime
  }
  deriving stock (Show, Eq, Ord)

instance Mapping.IsScalar TrackMetadata where
  scalarEncoder =
    Encoders.composite
      (Just "music_catalogue")
      "track_metadata"
      ( mconcat
          [ (.title) >$< Encoders.field (Encoders.nonNullable (Mapping.scalarEncoder)),
            (.metadata) >$< Encoders.field (Encoders.nullable (Encoders.array (Encoders.dimension Vector.foldl' (Encoders.element (Encoders.nullable Mapping.scalarEncoder))))),
            (.createdAt) >$< Encoders.field (Encoders.nonNullable (Mapping.scalarEncoder))
          ]
      )
  
  scalarDecoder =
    Decoders.composite
      (Just "music_catalogue")
      "track_metadata"
      ( TrackMetadata
          <$> Decoders.field (Decoders.nonNullable (Mapping.scalarDecoder))
          <*> Decoders.field (Decoders.nullable (Decoders.array (Decoders.dimension Vector.replicateM (Decoders.element (Decoders.nullable Mapping.scalarDecoder)))))
          <*> Decoders.field (Decoders.nonNullable (Mapping.scalarDecoder))
      )
  
