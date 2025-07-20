require "test_helper"

class UserFlowTest < ActionDispatch::IntegrationTest
  test "complete user registration and album management flow" do
    # User registration
    get new_user_registration_path
    assert_response :success

    post user_registration_path, params: {
      user: {
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    # Should redirect after successful registration
    assert_response :redirect
    follow_redirect!

    # User creates a new album
    get new_album_path
    assert_response :success

    post albums_path, params: {
      album: {
        title: "My First Album",
        year: 2020,
        format: "Vinyl",
        genre: [ "Rock" ]
      }
    }

    album = Album.last
    assert_redirected_to album_path(album)
    follow_redirect!

    assert_select "h1", "My First Album"

    # User edits the album
    get edit_album_path(album)
    assert_response :success

    patch album_path(album), params: {
      album: {
        title: "My Updated Album",
        notes: "Added some notes"
      }
    }

    assert_redirected_to album_path(album)
    follow_redirect!

    assert_select "h1", "My Updated Album"

    # User views all albums
    get albums_path
    assert_response :success
    # Check for the albums grid instead of specific data controller
    assert_select "h1", "Your Vinyl Collection"

    # User searches for albums
    get albums_path(q: "Updated")
    assert_response :success

    # User deletes the album
    delete album_path(album)
    assert_redirected_to albums_path

    # Verify album is deleted
    assert_raises(ActiveRecord::RecordNotFound) do
      Album.find(album.id)
    end
  end

  test "discogs authentication and search flow" do
    user = User.create!(
      email: "discogs@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # Sign in user
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    # User tries to search Discogs without authentication
    get search_discogs_albums_path
    assert_response :success

    get search_discogs_albums_path(query: "test")
    assert_response :success
    # Should not show results without authentication

    # User sets up Discogs credentials
    patch user_registration_path, params: {
      user: {
        discogs_username: "testuser",
        discogs_token: "testtoken",
        current_password: "password123"
      }
    }

    # User authenticates with Discogs
    user.reload
    user.update!(discogs_authenticated_at: Time.current)

    # Now user can search Discogs (would require mocking in real tests)
    get search_discogs_albums_path(query: "Beatles")
    assert_response :success
  end

  test "album filtering and search functionality" do
    user = User.create!(
      email: "filter@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # Create test data
    rock_artist = Artist.create!(name: "Rock Band")
    jazz_artist = Artist.create!(name: "Jazz Ensemble")

    rock_album = Album.create!(title: "Rock Album", year: 1990, format: "Vinyl", genre: [ "Rock" ])
    jazz_album = Album.create!(title: "Jazz Album", year: 2000, format: "CD", genre: [ "Jazz" ])

    rock_album.artists << rock_artist
    jazz_album.artists << jazz_artist

    # Sign in user
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    # Test filtering by genre
    get albums_path(genre: "Rock")
    assert_response :success

    # Test filtering by year
    get albums_path(year: 1990)
    assert_response :success

    # Test filtering by format
    get albums_path(format: "Vinyl")
    assert_response :success

    # Test searching by title
    get albums_path(q: "Rock")
    assert_response :success

    # Test combined filters
    get albums_path(genre: "Rock", year: 1990, format: "Vinyl")
    assert_response :success
  end
end
