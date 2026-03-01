module Demo.MusicCatalogue.Statements.SearchTracksByTitle where

import Demo.MusicCatalogue.Prelude
import qualified Hasql.Statement as Statement
import qualified Hasql.Decoders as Decoders
import qualified Hasql.Encoders as Encoders
import qualified Data.Aeson as Aeson
import qualified Data.Vector as Vector
import qualified Hasql.Mapping as Mapping
import qualified Demo.MusicCatalogue.Types as Types

-- |
-- Parameters for the @search_tracks_by_title@ query.
--
-- ==== SQL Template
--
-- > SELECT 
-- >     t.id,
-- >     t.title,
-- >     t.duration_seconds,
-- >     a.title as album_title,
-- >     ar.name as artist_name
-- > FROM tracks t
-- > JOIN albums a ON t.album_id = a.id
-- > JOIN artists ar ON a.artist_id = ar.id
-- > WHERE t.title ILIKE '%' || $search_term || '%' ORDER BY ar.name, a.title, t.track_number
--
-- ==== Source Path
--
-- > queries/search_tracks_by_title.sql
--
newtype SearchTracksByTitle = SearchTracksByTitle
  { -- | Maps to @search_term@.
    searchTerm :: Text
  }
  deriving stock (Eq, Show)

-- | Result of the statement parameterised by 'SearchTracksByTitle'.
type SearchTracksByTitleResult = Vector.Vector SearchTracksByTitleResultRow

-- | Row of 'SearchTracksByTitleResult'.
data SearchTracksByTitleResultRow = SearchTracksByTitleResultRow
  { -- | Maps to @id@.
    id :: UUID,
    -- | Maps to @title@.
    title :: Text,
    -- | Maps to @duration_seconds@.
    duration :: Maybe (Int32),
    -- | Maps to @album_title@.
    albumTitle :: Text,
    -- | Maps to @artist_name@.
    artistName :: Text
  }
  deriving stock (Show, Eq)


instance Mapping.IsStatement SearchTracksByTitle where
  type Result SearchTracksByTitle = SearchTracksByTitleResult

  statement = Statement.preparable sql encoder decoder
    where
      sql =
        "SELECT \n\
                \    t.id,\n\
                \    t.title,\n\
                \    t.duration_seconds,\n\
                \    a.title as album_title,\n\
                \    ar.name as artist_name\n\
                \FROM tracks t\n\
                \JOIN albums a ON t.album_id = a.id\n\
                \JOIN artists ar ON a.artist_id = ar.id\n\
                \WHERE t.title ILIKE '%' || $1 || '%' ORDER BY ar.name, a.title, t.track_number"

      encoder =
        mconcat
          [ (.searchTerm) >$< Encoders.param (Encoders.nonNullable (Mapping.scalarEncoder))
          ]

      decoder =
        Decoders.rowVector do
          id <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          title <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          duration <- Decoders.column (Decoders.nullable (Mapping.scalarDecoder))
          albumTitle <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          artistName <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          pure SearchTracksByTitleResultRow {..}

