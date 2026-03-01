module Demo.MusicCatalogue.Statements.GetTopTracksByPlayCount where

import Demo.MusicCatalogue.Prelude
import qualified Hasql.Statement as Statement
import qualified Hasql.Decoders as Decoders
import qualified Hasql.Encoders as Encoders
import qualified Data.Aeson as Aeson
import qualified Data.Vector as Vector
import qualified Hasql.Mapping as Mapping
import qualified Demo.MusicCatalogue.Types as Types

-- |
-- Parameters for the @get_top_tracks_by_play_count@ query.
--
-- ==== SQL Template
--
-- > SELECT 
-- >     t.id,
-- >     t.title,
-- >     ar.name as artist_name,
-- >     a.title as album_title,
-- >     COALESCE(p.play_count, 0) as play_count
-- > FROM tracks t
-- > JOIN albums a ON t.album_id = a.id
-- > JOIN artists ar ON a.artist_id = ar.id
-- > LEFT JOIN (
-- >     SELECT track_id, COUNT(*) as play_count
-- >     FROM play_history
-- >     GROUP BY track_id
-- > ) p ON t.id = p.track_id
-- > ORDER BY play_count DESC
-- > LIMIT $limit
--
-- ==== Source Path
--
-- > queries/get_top_tracks_by_play_count.sql
--
newtype GetTopTracksByPlayCount = GetTopTracksByPlayCount
  { -- | Maps to @limit@.
    limit :: Int32
  }
  deriving stock (Eq, Show)

-- | Result of the statement parameterised by 'GetTopTracksByPlayCount'.
type GetTopTracksByPlayCountResult = Vector.Vector GetTopTracksByPlayCountResultRow

-- | Row of 'GetTopTracksByPlayCountResult'.
data GetTopTracksByPlayCountResultRow = GetTopTracksByPlayCountResultRow
  { -- | Maps to @id@.
    id :: UUID,
    -- | Maps to @title@.
    title :: Text,
    -- | Maps to @artist_name@.
    artistName :: Text,
    -- | Maps to @album_title@.
    albumTitle :: Text,
    -- | Maps to @play_count@.
    playCount :: Int32
  }
  deriving stock (Show, Eq)


instance Mapping.IsStatement GetTopTracksByPlayCount where
  type Result GetTopTracksByPlayCount = GetTopTracksByPlayCountResult

  statement = Statement.preparable sql encoder decoder
    where
      sql =
        "SELECT \n\
                \    t.id,\n\
                \    t.title,\n\
                \    ar.name as artist_name,\n\
                \    a.title as album_title,\n\
                \    COALESCE(p.play_count, 0) as play_count\n\
                \FROM tracks t\n\
                \JOIN albums a ON t.album_id = a.id\n\
                \JOIN artists ar ON a.artist_id = ar.id\n\
                \LEFT JOIN (\n\
                \    SELECT track_id, COUNT(*) as play_count\n\
                \    FROM play_history\n\
                \    GROUP BY track_id\n\
                \) p ON t.id = p.track_id\n\
                \ORDER BY play_count DESC\n\
                \LIMIT $1"

      encoder =
        mconcat
          [ (.limit) >$< Encoders.param (Encoders.nonNullable (Mapping.scalarEncoder))
          ]

      decoder =
        Decoders.rowVector do
          id <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          title <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          artistName <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          albumTitle <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          playCount <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          pure GetTopTracksByPlayCountResultRow {..}

