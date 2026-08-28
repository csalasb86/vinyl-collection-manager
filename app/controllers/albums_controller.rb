class AlbumsController < ApplicationController
  include Pagy::Backend
  before_action :set_album, only: [ :show, :edit, :update, :destroy, :refresh_from_discogs ]

  def index
    @q = params[:q]
    @year = params[:year]
    @genre = params[:genre]
    @artist_id = params[:artist_id]
    @format = params[:format]

    albums = Album.all
      .by_query(@q)
      .by_year(@year)
      .by_genre(@genre)
      .by_artist(@artist_id)
      .by_format(@format)
      .includes(:artists)

    @pagy, @albums = pagy(albums, items: 24)

    @years = Album.where.not(year: nil).distinct.pluck(:year).sort.reverse
    @genres = Album.pluck(:genre).flatten.uniq.sort
    @artists = Artist.order(:name)
    @formats = Album.distinct.pluck(:format).compact.sort
  end

  def show
  end

  def new
    @album = Album.new
  end

  def create
    @album = Album.new(album_params)

    if @album.save
      redirect_to @album, notice: "Album was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @album.update(album_params)
      redirect_to @album, notice: "Album was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @album.destroy
    redirect_to albums_path, notice: "Album was successfully destroyed."
  end

  def search_discogs
    @query = params[:query]

    if @query.present? && current_user.discogs_authenticated?
      discogs_service = DiscogsService.new(current_user)
      begin
        @results = discogs_service.search_release(@query, per_page: 10)
      rescue DiscogsClient::Error => e
        Rails.logger.error("Discogs search failed: #{e.message}")
        @results = nil
        flash.now[:alert] = "Discogs search failed. Please check your Discogs credentials and try again."
      end
    else
      @results = nil
    end
  end

  def import_from_discogs
    discogs_id = params[:discogs_id]

    if discogs_id.present? && current_user.discogs_authenticated?
      discogs_service = DiscogsService.new(current_user)

      begin
        release = discogs_service.get_release(discogs_id)
        album = Album.find_or_create_from_discogs(release)

        if album.persisted?
          redirect_to album, notice: "Album was successfully imported from Discogs."
        else
          redirect_to search_discogs_albums_path(query: params[:query]), alert: "Failed to import album."
        end
      rescue => e
        redirect_to search_discogs_albums_path(query: params[:query]), alert: "Error importing from Discogs: #{e.message}"
      end
    else
      redirect_to search_discogs_albums_path(query: params[:query]), alert: "Invalid Discogs ID or not authenticated with Discogs."
    end
  end

  def refresh_from_discogs
    if @album.discogs_id.present? && current_user.discogs_authenticated?
      discogs_service = DiscogsService.new(current_user)

      begin
        release = discogs_service.get_release(@album.discogs_id)
        @album = Album.find_or_create_from_discogs(release, refresh: true)

        redirect_to @album, notice: "Album was successfully refreshed from Discogs."
      rescue => e
        redirect_to @album, alert: "Error refreshing from Discogs: #{e.message}"
      end
    else
      redirect_to @album, alert: "This album has no Discogs ID or you are not authenticated with Discogs."
    end
  end

  def sync_collection
    if current_user.discogs_authenticated?
      discogs_service = DiscogsService.new(current_user)
      result = discogs_service.sync_collection

      if result[:success]
        redirect_to albums_path, notice: "Successfully synchronized #{result[:albums_count]} albums from your Discogs collection."
      else
        redirect_to albums_path, alert: "Failed to sync collection: #{result[:error]}"
      end
    else
      redirect_to edit_user_registration_path, alert: "Please authenticate with Discogs first."
    end
  end

  private

  def set_album
    @album = Album.includes(:artists, :tracks).find(params[:id])
  end

  def album_params
    params.require(:album).permit(
      :title, :year, :format, :catalog_number, :notes, :cover,
      genre: [], artist_ids: []
    )
  end
end
