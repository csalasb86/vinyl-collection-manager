require "application_system_test_case"

# Rewritten against the interface that actually exists. The previous version was
# written speculatively — it looked for an "Albums" heading, an album-card
# Stimulus controller and a "Search" button that none of the views ever had, and
# had never run because there was no browser installed.
class AlbumsSystemTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "albums@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @artist = Artist.create!(name: "John Coltrane")
    @album = Album.create!(title: "Blue Train", year: 1957, format: "LP", genre: [ "Jazz" ])
    @album.artists << @artist

    sign_in_as(@user)
  end

  test "the collection lists the records" do
    visit albums_path

    assert_text "Blue Train"
    assert_text "John Coltrane"
    assert_text "1 album"
  end

  test "opening a record shows its details" do
    visit albums_path
    click_on "Blue Train"

    assert_selector "h1", text: "Blue Train"
    assert_text "John Coltrane"
    assert_text "1957"
    assert_text "LP"
  end

  test "adding a record by hand" do
    visit albums_path
    find("a[aria-label='Add album']").click

    assert_selector "h1", text: "Add a record"
    fill_in "Title", with: "A Love Supreme"
    fill_in "Year", with: "1965"
    select "LP", from: "Format"
    click_on "Add to collection"

    assert_text "Album was successfully created"
    assert_selector "h1", text: "A Love Supreme"
  end

  test "a record with no title is rejected with a reason" do
    visit new_album_path

    # Bypass the browser's own required-field check to reach the server side.
    page.execute_script("document.querySelector('#album_title').removeAttribute('required')")
    click_on "Add to collection"

    assert_text "stopped this from saving"
    assert_text "Title can't be blank"
  end

  test "editing a record" do
    visit album_path(@album)
    click_on "Edit"

    assert_selector "h1", text: "Edit record"
    fill_in "Title", with: "Blue Train (Reissue)"
    click_on "Save changes"

    assert_text "Album was successfully updated"
    assert_selector "h1", text: "Blue Train (Reissue)"
  end

  test "deleting a record asks first" do
    visit album_path(@album)

    accept_confirm do
      click_on "Delete"
    end

    assert_text "Album was successfully destroyed"
    assert_current_path albums_path
    assert_no_text "Blue Train"
  end

  test "a genre on the detail page filters the collection by it" do
    visit album_path(@album)

    click_on "Jazz"

    assert_current_path(/genre=Jazz/)
    assert_selector "a[aria-label='Remove filter Genre: Jazz']"
  end

  test "Discogs search asks for credentials before searching" do
    visit search_discogs_albums_path

    assert_selector "h1", text: "Search Discogs"
    assert_text "Connect your Discogs account before searching"
  end
end
