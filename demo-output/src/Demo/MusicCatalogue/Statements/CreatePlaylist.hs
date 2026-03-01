module Demo.MusicCatalogue.Statements.CreatePlaylist where

import Demo.MusicCatalogue.Prelude
import qualified Hasql.Statement as Statement
import qualified Hasql.Decoders as Decoders
import qualified Hasql.Encoders as Encoders
import qualified Data.Aeson as Aeson
import qualified Data.Vector as Vector
import qualified Hasql.Mapping as Mapping
import qualified Demo.MusicCatalogue.Types as Types

-- |
-- Parameters for the @create_playlist@ query.
--
-- ==== SQL Template
--
-- > INSERT INTO playlists (name, description, user_id, created_at)
-- > VALUES ($name, $description, $user_id, NOW())
-- > RETURNING id, name, created_at
--
-- ==== Source Path
--
-- > queries/create_playlist.sql
--
data CreatePlaylist = CreatePlaylist
  { -- | Maps to @name@.
    name :: Text,
    -- | Maps to @description@.
    description :: Maybe (Text),
    -- | Maps to @user_id@.
    userId :: UUID
  }
  deriving stock (Eq, Show)

-- | Result of the statement parameterised by 'CreatePlaylist'.
type CreatePlaylistResult = CreatePlaylistResultRow

-- | Row of 'CreatePlaylistResult'.
data CreatePlaylistResultRow = CreatePlaylistResultRow
  { -- | Maps to @id@.
    id :: UUID,
    -- | Maps to @name@.
    name :: Text,
    -- | Maps to @created_at@.
    createdAt :: LocalTime
  }
  deriving stock (Show, Eq)


instance Mapping.IsStatement CreatePlaylist where
  type Result CreatePlaylist = CreatePlaylistResult

  statement = Statement.preparable sql encoder decoder
    where
      sql =
        "INSERT INTO playlists (name, description, user_id, created_at)\n\
                \VALUES ($2, $3, $1, NOW())\n\
                \RETURNING id, name, created_at"

      encoder =
        mconcat
          [ (.name) >$< Encoders.param (Encoders.nonNullable (Mapping.scalarEncoder)),
            (.description) >$< Encoders.param (Encoders.nullable (Mapping.scalarEncoder)),
            (.userId) >$< Encoders.param (Encoders.nonNullable (Mapping.scalarEncoder))
          ]

      decoder =
        Decoders.singleRow do
          id <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          name <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          createdAt <- Decoders.column (Decoders.nonNullable (Mapping.scalarDecoder))
          pure CreatePlaylistResultRow {..}

