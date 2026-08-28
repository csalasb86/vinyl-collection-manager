module AlbumsHelper
  # The filters currently narrowing the collection, as { label:, param:, value: }.
  # Rendered as chips so what is applied is visible without opening the panel.
  def active_filters
    @active_filters ||= [
      { param: :q,         key: :search, value: params[:q] },
      { param: :year,      key: :year,   value: params[:year] },
      { param: :genre,     key: :genre,  value: params[:genre] },
      { param: :format,    key: :format, value: params[:format] },
      { param: :artist_id, key: :artist, value: artist_name(params[:artist_id]) }
    ].select { |filter| filter[:value].present? }
     .map { |filter| filter.merge(label: t("vinyl_collection.albums.results.filter_#{filter[:key]}")) }
  end

  # [[label, key]] for the sort select — the whitelist is Album::SORTS, the
  # wording lives in the locale file.
  def sort_options
    Album::SORTS.map { |key| [ t("vinyl_collection.albums.sorts.#{key}"), key ] }
  end

  # The same page with one filter dropped — the chip's remove link.
  def path_without_filter(param)
    albums_path(filter_params.except(param.to_s))
  end

  def path_without_filters
    albums_path(params[:sort].present? ? { sort: params[:sort] } : {})
  end

  def filter_params
    params.permit(:q, :year, :genre, :format, :artist_id, :sort).to_h.compact_blank
  end

  # Discogs notes come back with BBCode: [url=...]label[/url] for releases,
  # [a=Artist] / [l=Label] / [m=123] for entities, plus [b] and friends. Shown
  # raw it reads as markup, so unwrap the readable part and drop the tags.
  # Plain text on purpose — it goes through simple_format, which escapes.
  DISCOGS_URL_TAG = %r{\[url(?:=[^\]]+)?\](.*?)\[/url\]}im
  DISCOGS_NAMED_TAG = /\[[almr]=([^\]]+)\]/i
  DISCOGS_ANY_TAG = %r{\[/?(?:url|b|i|u|s|q|quote|code|center|strike)\b[^\]]*\]}i

  def discogs_notes(text)
    return if text.blank?

    text.gsub(DISCOGS_URL_TAG) { Regexp.last_match(1) }
        .gsub(DISCOGS_NAMED_TAG) { Regexp.last_match(1) }
        .gsub(DISCOGS_ANY_TAG, "")
  end

  def cover_alt(album)
    artists = album.display_artists

    if artists.present?
      t("vinyl_collection.albums.card.cover_alt", title: album.title, artists: artists)
    else
      t("vinyl_collection.albums.card.cover_alt_untitled", title: album.title)
    end
  end

  private

  def artist_name(artist_id)
    return if artist_id.blank?

    Artist.find_by(id: artist_id)&.name
  end
end
