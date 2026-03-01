module Demo.MusicCatalogue.Statements.GetTrackDetails where

import Demo.MusicCatalogue.Prelude
import qualified Hasql.Statement as Statement
import qualified Hasql.Decoders as Decoders
import qualified Hasql.Encoders as Encoders
import qualified Data.Aeson as Aeson
import qualified Data.Vector as Vector
import qualified Hasql.Mapping as Mapping
import qualified Demo.MusicCatalogue.Types as Types

-- |
-- Parameters for the @get_track_details@ query.
--
-- ==== SQL Template
--
-- > SELECT 
-- >     t.id,
-- >     t.title,
-- >     t.duration_seconds,
-- >     t.track_number,
-- >     a.id as album_id,
-- >     a.title as album_title,
-- >     ar.id as artist_id,
-- >     ar.name as artist_name,
-- >     g.name as genre
-- > FROM tracks t
-- > JOIN albums a ON t.album_id = a.id
-- > JOIN artists ar ON a.artist_id = ar.id
-- > LEFT JOIN genres g ON t.genre_id = g.id
-- > WHERE t.id = $track_id
--
-- ==== Source Path
--
-- > queries/get_track_details.sql
--
newtype GetTrackDetails = GetTrackDetails
  { -- | Maps to @track_id@.
    trackId :: UUID
  }
  deriving stock (Eq, Show)

-- | Result of the statement parameterised by 'GetTrackDetails'.
type GetTrackDetailsResult = GetTrackDetailsResultRow

-- | Row of 'GetTrackDetailsResult'.
data GetTrackDetailsResultRow = GetTrackDetailsResultRow
  { -- | Maps to @id@.
    id :: UUID,
    -- | Maps to @title@.
    title :: Text,
    -- | Maps to @duration_seconds@.
    duration :: Maybe (Int32),
    -- | Maps to @track_number@.
    trackNumber :: Maybe (Int32),
    -- | Maps to @album_id@.
    albumId :: UUID,
    -- | Maps to @album_title@.
    albumTitle :: Text,
    -- | Maps to @artist_id@.
    artistId :: UUID,
    -- | Maps to @artist_name@.
    artistName :: Text,
    -- | Maps to @genre@.
    genre :: Maybe (Text)
  }
  deriving stock (Show, Eq)


instance Mapping.IsStatement GetTrackDetails where
  type Result GetTrackDetails = GetTrackDetailsResult

  statement = Statement.preparable sql encoder decoder
    where
      sql =
        "SELECT \n\
                \    t.id,\n\
                \    t.title,\n\
                \    t.duration_seconds,\n\
                \    t.track_number,\n\
                \    a.id as album_id,\n\
                \    a.title as album_title,\n\
                \    ar.id as artist_id,\n\
                \    ar.name as artist_name,\n\
                \    g.name as genre\n\
                \FROM tracks t\n\
                \JOIN albums a ON t.album_id = a.id\n\
                \JOIN artists ar ON a.artist_id = ar.id\n\
                \LEFT JOIN genres g ON t.genre_id = g.id\n\
                \WHERE t.id = $1"

      encoder =
        mconcat
          [ (.trackId) >$< Encoders.param (Encoders.nonNullable (Mapping.scalarEncoder))
          ]

      decoder =
        Decoders.singleRow do
          id <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          title <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          duration <- Decoders.column (Decoders.nullable (Mapping.scalarDecoder))
          trackNumber <- Decoders.column (Decoders.nullable (Mapping.scalarDecoder))
          albumId <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          albumTitle <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          artistId <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          artistName <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          genre <- Decoders.column (Decoders.nullable (Mapping.scalarDecoder))
          pure GetTrackDetailsResultRow {..}

