class Album < ApplicationRecord
  has_many :album_artists, dependent: :destroy
  has_many :artists, through: :album_artists
  has_many :tracks, -> { order(:position_index) }, dependent: :destroy

  has_one_attached :cover

  validates :title, presence: true
  validates :discogs_id, uniqueness: true, allow_nil: true

  # Discogs sends year: 0 for releases with no known year, and the form can
  # submit a blank that casts to 0. Unknown is NULL, never zero.
  before_validation :normalize_unknown_year

  scope :by_year, ->(year) { where(year: year) if year.present? }
  scope :by_genre, ->(genre) { where("genre && ARRAY[?]::varchar[]", [ genre ]) if genre.present? }
  scope :by_format, ->(format) { where(format: format) if format.present? }

  # Both of these match through artists with a subquery rather than a join on
  # the outer relation: a join multiplies the row per matching artist, which
  # showed the same album twice. LEFT JOIN inside so an album with no artist is
  # still findable by its title.
  scope :by_artist, ->(artist_id) {
    where(id: AlbumArtist.where(artist_id: artist_id).select(:album_id)) if artist_id.present?
  }

  scope :by_query, ->(query) {
    next if query.blank?

    like = "%#{query}%"
    where(id: Album.left_joins(:artists)
                   .where("albums.title ILIKE :like OR artists.name ILIKE :like", like: like)
                   .select(:id))
  }

  # Whitelisted so an ORDER BY can never come from a request parameter.
  # Labels live in the locale file, not here.
  SORTS = %w[recent title newest oldest].freeze

  scope :sorted_by, ->(key) {
    case key
    when "title"  then order(Arel.sql("LOWER(albums.title) ASC"))
    when "newest" then order(Arel.sql("albums.year DESC NULLS LAST")).order(:title)
    when "oldest" then order(Arel.sql("albums.year ASC NULLS LAST")).order(:title)
    else               order(created_at: :desc)
    end
  }

  # Imports a Discogs release.
  #
  # refresh: false (import and collection sync) creates albums that are new and
  # leaves existing ones untouched, only backfilling a tracklist or cover that
  # never made it in. Every Discogs field is editable in the album form, so a
  # sync must not silently overwrite what the user typed.
  #
  # refresh: true ("Refresh from Discogs") is the user explicitly asking for the
  # Discogs version, so attributes, tracklist and cover are all overwritten.
  def self.find_or_create_from_discogs(discogs_release, refresh: false)
    album = find_or_initialize_by(discogs_id: discogs_release.id)
    overwrite = album.new_record? || refresh

    assign_discogs_attributes(album, discogs_release) if overwrite
    album.save!

    assign_discogs_artists(album, discogs_release.artists) if overwrite
    sync_discogs_tracks(album, discogs_release.tracklist) if overwrite || album.tracks.empty?
    attach_discogs_cover(album, discogs_release.images) if overwrite || !album.cover.attached?

    album
  end

  def self.assign_discogs_attributes(album, discogs_release)
    album.title = discogs_release.title
    album.year = discogs_release.year.to_i.positive? ? discogs_release.year : nil
    album.format = discogs_release.formats&.first&.dig("name") || "Vinyl"
    album.genre = discogs_release.genres || []
    album.discogs_url = discogs_release.uri
    album.catalog_number = discogs_release.labels&.first&.dig("catno")
    album.notes = discogs_release.notes
  end
  private_class_method :assign_discogs_attributes

  def self.assign_discogs_artists(album, discogs_artists)
    album.artists = Array(discogs_artists).map do |discogs_artist|
      Artist.find_or_create_from_discogs(discogs_artist)
    end.uniq
  end
  private_class_method :assign_discogs_artists

  # Mirrors the Discogs tracklist: updates tracks whose position already exists,
  # adds the new ones and drops the ones the release no longer has.
  def self.sync_discogs_tracks(album, discogs_tracklist)
    kept_ids = Array(discogs_tracklist).each_with_index.filter_map do |discogs_track, index|
      next if discogs_track.position.blank? || discogs_track.title.blank?

      track = album.tracks.find_or_initialize_by(position: discogs_track.position)
      track.title = discogs_track.title
      track.duration = discogs_track.duration
      track.position_index = index + 1
      track.save!
      track.id
    end

    album.tracks.where.not(id: kept_ids).destroy_all
  end
  private_class_method :sync_discogs_tracks

  def self.attach_discogs_cover(album, images)
    primary_image = Array(images).find { |img| img.type == "primary" } || Array(images).first
    return if primary_image&.uri.blank?

    response = Faraday.get(primary_image.uri)
    return unless response.success?

    album.cover.attach(
      io: StringIO.new(response.body),
      filename: "#{album.title.parameterize}.jpg",
      content_type: "image/jpeg"
    )
  rescue => e
    Rails.logger.error("Failed to download cover for album #{album.id}: #{e.message}")
  end
  private_class_method :attach_discogs_cover

  def display_artists
    artists.map(&:name).join(", ")
  end

  def cover_url
    if cover.attached?
      Rails.application.routes.url_helpers.rails_blob_url(cover, only_path: true)
    else
      ActionController::Base.helpers.asset_path("placeholder_album.png")
    end
  end

  # Year for display: releases with no known year read as "Unknown", not "0".
  def year_label
    year.presence || I18n.t("vinyl_collection.albums.unknown_year")
  end

  private

  def normalize_unknown_year
    self.year = nil unless year.to_i.positive?
  end
end
