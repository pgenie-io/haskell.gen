module Demo.MusicCatalogue.Statements.GetAlbumsByArtist where

import Demo.MusicCatalogue.Prelude
import qualified Hasql.Statement as Statement
import qualified Hasql.Decoders as Decoders
import qualified Hasql.Encoders as Encoders
import qualified Data.Aeson as Aeson
import qualified Data.Vector as Vector
import qualified Hasql.Mapping as Mapping
import qualified Demo.MusicCatalogue.Types as Types

-- |
-- Parameters for the @get_albums_by_artist@ query.
--
-- ==== SQL Template
--
-- > SELECT 
-- >     a.id,
-- >     a.title,
-- >     a.release_year,
-- >     a.album_type
-- > FROM albums a
-- > WHERE a.artist_id = $artist_id ORDER BY a.release_year DESC
--
-- ==== Source Path
--
-- > queries/get_albums_by_artist.sql
--
newtype GetAlbumsByArtist = GetAlbumsByArtist
  { -- | Maps to @artist_id@.
    artistId :: UUID
  }
  deriving stock (Eq, Show)

-- | Result of the statement parameterised by 'GetAlbumsByArtist'.
type GetAlbumsByArtistResult = Vector.Vector GetAlbumsByArtistResultRow

-- | Row of 'GetAlbumsByArtistResult'.
data GetAlbumsByArtistResultRow = GetAlbumsByArtistResultRow
  { -- | Maps to @id@.
    id :: UUID,
    -- | Maps to @title@.
    title :: Text,
    -- | Maps to @release_year@.
    releaseYear :: Maybe (Int32),
    -- | Maps to @album_type@.
    albumType :: Types.AlbumType
  }
  deriving stock (Show, Eq)


instance Mapping.IsStatement GetAlbumsByArtist where
  type Result GetAlbumsByArtist = GetAlbumsByArtistResult

  statement = Statement.preparable sql encoder decoder
    where
      sql =
        "SELECT \n\
                \    a.id,\n\
                \    a.title,\n\
                \    a.release_year,\n\
                \    a.album_type\n\
                \FROM albums a\n\
                \WHERE a.artist_id = $1 ORDER BY a.release_year DESC"

      encoder =
        mconcat
          [ (.artistId) >$< Encoders.param (Encoders.nonNullable (Mapping.scalarEncoder))
          ]

      decoder =
        Decoders.rowVector do
          id <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          title <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          releaseYear <- Decoders.column (Decoders.nullable (Mapping.scalarDecoder))
          albumType <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          pure GetAlbumsByArtistResultRow {..}

