class Artist < ApplicationRecord
  has_many :album_artists, dependent: :destroy
  has_many :albums, through: :album_artists

  validates :name, presence: true
  validates :discogs_id, uniqueness: true, allow_nil: true

  def self.find_or_create_from_discogs(discogs_artist)
    find_or_create_by(discogs_id: discogs_artist.id) do |artist|
    artist.name = discogs_artist.name
    artist.profile = discogs_artist.profile
    artist.discogs_url = discogs_artist.uri
    end
  end
end
