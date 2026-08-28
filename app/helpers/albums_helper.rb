module AlbumsHelper
  # The filters currently narrowing the collection, as { label:, param:, value: }.
  # Rendered as chips so what is applied is visible without opening the panel.
  def active_filters
    [
      { param: :q,         label: "Search",  value: params[:q] },
      { param: :year,      label: "Year",    value: params[:year] },
      { param: :genre,     label: "Genre",   value: params[:genre] },
      { param: :format,    label: "Format",  value: params[:format] },
      { param: :artist_id, label: "Artist",  value: artist_name(params[:artist_id]) }
    ].select { |filter| filter[:value].present? }
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

  def cover_alt(album)
    artists = album.display_artists
    artists.present? ? "Cover of #{album.title} by #{artists}" : "Cover of #{album.title}"
  end

  private

  def artist_name(artist_id)
    return if artist_id.blank?

    Artist.find_by(id: artist_id)&.name
  end
end
