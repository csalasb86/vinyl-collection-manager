class AlbumArtist < ApplicationRecord
  belongs_to :album
  belongs_to :artist

  validates :album_id, uniqueness: { scope: :artist_id }
end
