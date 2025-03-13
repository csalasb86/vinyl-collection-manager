class Album < ApplicationRecord
  has_many :album_artists, dependent: :destroy
  has_many :artists, through: :album_artists
  has_many :tracks, dependent: :destroy
  
  has_one_attached :cover
  
  validates :title, presence: true
  validates :discogs_id, uniqueness: true, allow_nil: true
  
  scope :by_year, ->(year) { where(year: year) if year.present? }
  scope :by_genre, ->(genre) { where("genre && ARRAY[?]::varchar[]", [genre]) if genre.present? }
  scope :by_artist, ->(artist_id) { joins(:artists).where(artists: { id: artist_id }) if artist_id.present? }
  scope :by_format, ->(format) { where(format: format) if format.present? }
  scope :by_query, ->(query) { 
    where("title ILIKE ? OR artists.name ILIKE ?", "%#{query}%", "%#{query}%")
    .joins(:artists) if query.present?
  }
  
  def self.find_or_create_from_discogs(discogs_release)
    album = find_or_create_by(discogs_id: discogs_release.id) do |album|
      album.title = discogs_release.title
      album.year = discogs_release.year
      album.format = discogs_release.formats&.first&.dig("name") || "Vinyl"
      album.genre = discogs_release.genres || []
      album.discogs_url = discogs_release.uri
      album.catalog_number = discogs_release.labels&.first&.dig("catno")
      album.notes = discogs_release.notes
    end
    
    # Associate artists
    discogs_release.artists&.each do |discogs_artist|
      artist = Artist.find_or_create_from_discogs(discogs_artist)
      album.artists << artist unless album.artists.include?(artist)
    end
    
    # Create tracks
    discogs_release.tracklist&.each_with_index do |discogs_track, index|
      next if discogs_track.position.blank? || discogs_track.title.blank?
      
      album.tracks.find_or_create_by(position: discogs_track.position) do |track|
        track.title = discogs_track.title
        track.duration = discogs_track.duration
        track.position_index = index + 1
      end
    end
    
    # Download cover image if available
    if discogs_release.images&.any?
      primary_image = discogs_release.images.find { |img| img.type == "primary" } || discogs_release.images.first
      if primary_image&.uri.present?
        begin
          response = Faraday.get(primary_image.uri)
          if response.success?
            album.cover.attach(
              io: StringIO.new(response.body),
              filename: "#{album.title.parameterize}.jpg",
              content_type: 'image/jpeg'
            )
          end
        rescue => e
          Rails.logger.error("Failed to download cover for album #{album.id}: #{e.message}")
        end
      end
    end
    
    album
  end
  
  def display_artists
    artists.map(&:name).join(", ")
  end
  
  def cover_url
    if cover.attached?
      Rails.application.routes.url_helpers.rails_blob_url(cover, only_path: true)
    else
      ActionController::Base.helpers.asset_path('placeholder_album.png')
    end
  end
end