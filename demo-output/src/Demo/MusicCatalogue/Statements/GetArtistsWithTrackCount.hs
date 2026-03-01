module Demo.MusicCatalogue.Statements.GetArtistsWithTrackCount where

import Demo.MusicCatalogue.Prelude
import qualified Hasql.Statement as Statement
import qualified Hasql.Decoders as Decoders
import qualified Hasql.Encoders as Encoders
import qualified Data.Aeson as Aeson
import qualified Data.Vector as Vector
import qualified Hasql.Mapping as Mapping
import qualified Demo.MusicCatalogue.Types as Types

-- |
-- Parameters for the @get_artists_with_track_count@ query.
--
-- ==== SQL Template
--
-- > SELECT 
-- >     ar.id,
-- >     ar.name,
-- >     COUNT(DISTINCT t.id) as track_count,
-- >     COUNT(DISTINCT a.id) as album_count
-- > FROM artists ar
-- > LEFT JOIN albums a ON ar.id = a.artist_id
-- > LEFT JOIN tracks t ON a.id = t.album_id
-- > GROUP BY ar.id, ar.name
-- > ORDER BY track_count DESC
--
-- ==== Source Path
--
-- > queries/get_artists_with_track_count.sql
--
data GetArtistsWithTrackCount = GetArtistsWithTrackCount
  deriving stock (Eq, Show)

-- | Result of the statement parameterised by 'GetArtistsWithTrackCount'.
type GetArtistsWithTrackCountResult = Vector.Vector GetArtistsWithTrackCountResultRow

-- | Row of 'GetArtistsWithTrackCountResult'.
data GetArtistsWithTrackCountResultRow = GetArtistsWithTrackCountResultRow
  { -- | Maps to @id@.
    id :: UUID,
    -- | Maps to @name@.
    name :: Text,
    -- | Maps to @track_count@.
    trackCount :: Int32,
    -- | Maps to @album_count@.
    albumCount :: Int32
  }
  deriving stock (Show, Eq)


instance Mapping.IsStatement GetArtistsWithTrackCount where
  type Result GetArtistsWithTrackCount = GetArtistsWithTrackCountResult

  statement = Statement.preparable sql encoder decoder
    where
      sql =
        "SELECT \n\
                \    ar.id,\n\
                \    ar.name,\n\
                \    COUNT(DISTINCT t.id) as track_count,\n\
                \    COUNT(DISTINCT a.id) as album_count\n\
                \FROM artists ar\n\
                \LEFT JOIN albums a ON ar.id = a.artist_id\n\
                \LEFT JOIN tracks t ON a.id = t.album_id\n\
                \GROUP BY ar.id, ar.name\n\
                \ORDER BY track_count DESC"

      encoder =
        mconcat
          [ 
          ]

      decoder =
        Decoders.rowVector do
          id <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          name <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          trackCount <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          albumCount <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          pure GetArtistsWithTrackCountResultRow {..}

