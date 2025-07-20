require "application_system_test_case"

class AlbumsSystemTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @album = Album.create!(title: "Test Album", year: 1990, format: "Vinyl")
    @artist = Artist.create!(name: "Test Artist")
    @album.artists << @artist
    sign_in_user(@user)
  end

  test "visiting the albums index" do
    visit albums_url

    assert_selector "h1", text: "Albums"
    assert_selector "div[data-controller='album-card']"
  end

  test "searching albums" do
    visit albums_url

    fill_in "Search albums...", with: "Test"
    click_on "Search"

    assert_text @album.title
  end

  test "filtering albums by year" do
    visit albums_url

    select "1990", from: "year"
    click_on "Search"

    assert_text @album.title
  end

  test "creating a new album" do
    visit albums_url
    click_on "Add Album"

    fill_in "Title", with: "New System Test Album"
    fill_in "Year", with: "2020"
    select "Vinyl", from: "Format"

    click_on "Create Album"

    assert_text "Album was successfully created"
    assert_text "New System Test Album"
  end

  test "viewing an album" do
    visit album_url(@album)

    assert_selector "h1", text: @album.title
    assert_text @artist.name
    assert_text @album.year.to_s
    assert_text @album.format
  end

  test "editing an album" do
    visit album_url(@album)
    click_on "Edit"

    fill_in "Title", with: "Updated Album Title"
    click_on "Update Album"

    assert_text "Album was successfully updated"
    assert_text "Updated Album Title"
  end

  test "deleting an album" do
    visit album_url(@album)

    accept_confirm do
      click_on "Delete"
    end

    assert_text "Album was successfully destroyed"
    assert_current_path albums_path
  end

  test "searching discogs" do
    @user.update!(
      discogs_token: "test_token",
      discogs_username: "test_user",
      discogs_authenticated_at: Time.current
    )

    visit albums_url
    click_on "Search Discogs"

    assert_text "Search Discogs Database"

    fill_in "Search for albums...", with: "Beatles"
    click_on "Search"

    # Note: This would require mocking the Discogs API in a real test
    assert_current_path search_discogs_albums_path
  end

  test "user authentication flow for discogs features" do
    visit albums_url
    click_on "Search Discogs"

    # Should show search form but results require authentication
    assert_text "Search Discogs Database"

    fill_in "Search for albums...", with: "Test"
    click_on "Search"

    # Without authentication, no results should be shown
    assert_no_text "Import"
  end

  private

  def sign_in_user(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_on "Log in"
  end
end
