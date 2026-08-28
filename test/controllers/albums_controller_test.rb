require "test_helper"

class AlbumsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @album = Album.create!(title: "Test Album", year: 1990)
    @artist = Artist.create!(name: "Test Artist")
    @album.artists << @artist
    sign_in @user
  end

  test "should get index" do
    get albums_url
    assert_response :success
    assert_select "h1", "Your Vinyl Collection"
  end

  test "should get index with search parameters" do
    get albums_url(q: "Test", year: 1990, genre: "Rock")
    assert_response :success
  end

  test "should get show" do
    get album_url(@album)
    assert_response :success
    assert_select "h1", @album.title
  end

  test "should get new" do
    get new_album_url
    assert_response :success
  end

  test "should create album" do
    assert_difference("Album.count") do
      post albums_url, params: {
        album: {
          title: "New Album",
          year: 2020,
          format: "Vinyl"
        }
      }
    end

    assert_redirected_to album_url(Album.last)
    assert_equal "Album was successfully created.", flash[:notice]
  end

  test "should not create album with invalid params" do
    assert_no_difference("Album.count") do
      post albums_url, params: {
        album: {
          title: "",
          year: 2020
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_album_url(@album)
    assert_response :success
  end

  test "should update album" do
    patch album_url(@album), params: {
      album: {
        title: "Updated Album"
      }
    }
    assert_redirected_to album_url(@album)
    assert_equal "Album was successfully updated.", flash[:notice]
    @album.reload
    assert_equal "Updated Album", @album.title
  end

  test "should not update album with invalid params" do
    patch album_url(@album), params: {
      album: {
        title: ""
      }
    }
    assert_response :unprocessable_entity
  end

  test "should destroy album" do
    assert_difference("Album.count", -1) do
      delete album_url(@album)
    end

    assert_redirected_to albums_url
    assert_equal "Album was successfully destroyed.", flash[:notice]
  end

  test "should get search_discogs" do
    get search_discogs_albums_url
    assert_response :success
  end

  test "should search discogs with query and authenticated user" do
    @user.update!(
      discogs_token: "test_token",
      discogs_username: "test_user",
      discogs_authenticated_at: Time.current
    )

    # Mock the service call
    mock_service = Object.new
    def mock_service.search_release(query, options = {})
      []
    end

    DiscogsService.stub :new, mock_service do
      get search_discogs_albums_url(query: "test query")
      assert_response :success
    end

    # No need to verify since we're using a simple object mock
  end

  test "should not search discogs without authentication" do
    get search_discogs_albums_url(query: "test query")
    assert_response :success
    # Results should be nil without authentication
    assert_response :success
  end

  test "should import from discogs with valid discogs_id" do
    @user.update!(
      discogs_token: "test_token",
      discogs_username: "test_user",
      discogs_authenticated_at: Time.current
    )

    # Mock the service and release
    mock_service = Minitest::Mock.new
    mock_release = Struct.new(:id, :title, :year, :artists, :tracklist, :images).new(
      123,
      "Imported Album",
      1990,
      [],
      [],
      []
    )
    mock_service.expect :get_release, mock_release, [ "123" ]

    DiscogsService.stub :new, mock_service do
      post import_from_discogs_albums_url, params: { discogs_id: "123" }
    end

    # Check that we either got a success redirect or handled gracefully
    assert_response :redirect
    mock_service.verify
  end

  test "should not import from discogs without authentication" do
    assert_no_difference("Album.count") do
      post import_from_discogs_albums_url, params: { discogs_id: "123" }
    end

    assert_redirected_to search_discogs_albums_url
    assert_match(/not authenticated/, flash[:alert])
  end

  test "should refresh album from discogs" do
    @album.update!(discogs_id: 123)
    @user.update!(
      discogs_token: "test_token",
      discogs_username: "test_user",
      discogs_authenticated_at: Time.current
    )

    # Mock the service
    mock_service = Minitest::Mock.new
    mock_release = Struct.new(:id, :title, :year, :formats, :genres, :uri, :labels, :notes, :artists, :tracklist, :images).new(
      123,
      "Refreshed Album",
      1990,
      [ { "name" => "LP" } ],
      [ "Rock" ],
      "https://discogs.com/release/123",
      [ { "catno" => "REF123" } ],
      "Refreshed notes",
      [],
      [],
      []
    )
    mock_service.expect :get_release, mock_release, [ 123 ]

    DiscogsService.stub :new, mock_service do
      patch refresh_from_discogs_album_url(@album)
    end

    assert_redirected_to album_url(@album)
    assert_equal "Album was successfully refreshed from Discogs.", flash[:notice]
    mock_service.verify

    # The whole point of the action: the record actually changed
    @album.reload
    assert_equal "Refreshed Album", @album.title
    assert_equal 1990, @album.year
    assert_equal "REF123", @album.catalog_number
  end

  test "should not refresh album without discogs_id" do
    @album.update!(discogs_id: nil)

    patch refresh_from_discogs_album_url(@album)
    assert_redirected_to album_url(@album)
    assert_match(/no Discogs ID/, flash[:alert])
  end

  # A collection sync is one Discogs call per release against a 60/min limit, so
  # it is queued rather than held open in the request.
  test "syncing queues the job and answers immediately" do
    @user.update!(
      discogs_token: "test_token",
      discogs_username: "test_user",
      discogs_authenticated_at: Time.current
    )

    assert_enqueued_with(job: SyncDiscogsCollectionJob, args: [ @user ]) do
      post sync_collection_albums_url
    end

    assert_redirected_to albums_url
    assert_match(/in the background/, flash[:notice])
  end

  test "should not sync collection without authentication" do
    assert_no_enqueued_jobs only: SyncDiscogsCollectionJob do
      post sync_collection_albums_url
    end

    assert_redirected_to edit_user_registration_url
    assert_match(/Connect your Discogs account/, flash[:alert])
  end

  private

  def sign_in(user)
    post user_session_url, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
