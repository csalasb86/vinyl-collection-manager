require "test_helper"

class CollectionFilteringTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "filters@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }

    @coltrane = Artist.create!(name: "John Coltrane")
    @blue = Album.create!(title: "Blue Train", year: 1957, format: "LP", genre: [ "Jazz" ])
    @blue.artists << @coltrane
    @solo = Album.create!(title: "Untitled Solo", year: 1999, format: "7\"", genre: [ "Rock" ])
    @undated = Album.create!(title: "No Year Here", format: "LP", genre: [ "Rock" ])
  end

  test "search matches on title and on artist name" do
    get albums_path(q: "Blue Train")
    assert_select "h3", text: "Blue Train"

    get albums_path(q: "Coltrane")
    assert_select "h3", text: "Blue Train"
  end

  # An INNER JOIN on artists used to make an album with no artist unfindable.
  test "an album with no artist is still findable by title" do
    assert_empty @solo.artists

    get albums_path(q: "Untitled Solo")

    assert_select "h3", text: "Untitled Solo"
  end

  # Joining artists on the outer relation returned one row per matching artist.
  test "an album with several matching artists appears once" do
    @blue.artists << Artist.create!(name: "Coltrane Quartet")

    get albums_path(q: "Coltrane")

    assert_select "h3", text: "Blue Train", count: 1
  end

  test "each filter narrows the collection" do
    get albums_path(year: 1957)
    assert_select "h3", text: "Blue Train"
    assert_select "h3", text: "Untitled Solo", count: 0

    get albums_path(genre: "Rock")
    assert_select "h3", text: "Untitled Solo"
    assert_select "h3", text: "Blue Train", count: 0

    get albums_path(format: "LP")
    assert_select "h3", text: "Untitled Solo", count: 0

    get albums_path(artist_id: @coltrane.id)
    assert_select "h3", text: "Blue Train"
    assert_select "h3", text: "Untitled Solo", count: 0
  end

  test "an applied filter shows a chip that links to the collection without it" do
    get albums_path(q: "Blue", genre: "Jazz")

    assert_select "a[aria-label=?]", "Remove filter Search: Blue"
    assert_select "a[aria-label=?]", "Remove filter Genre: Jazz"
    assert_select "a[href=?]", albums_path(genre: "Jazz")
    assert_select "a[href=?]", albums_path(q: "Blue")
  end

  test "the artist chip shows the name rather than the id" do
    get albums_path(artist_id: @coltrane.id)

    assert_select "a[aria-label=?]", "Remove filter Artist: John Coltrane"
  end

  test "sorting is limited to the whitelist and falls back to the default" do
    get albums_path(sort: "title; DROP TABLE albums")

    assert_response :success
    assert_select "select#sort option[selected]", text: "Recently added"
    assert Album.exists?
  end

  test "albums with no year sort last, not first" do
    get albums_path(sort: "newest")

    titles = css_select("h3").map(&:text)
    assert_equal "No Year Here", titles.last
  end

  test "an empty collection and an empty result set say different things" do
    get albums_path(q: "nothing matches this")
    assert_match "Nothing matches these filters", response.body

    Album.destroy_all
    get albums_path
    assert_match "Your crate is empty", response.body
  end

  test "results render inside the turbo frame the toolbar targets" do
    get albums_path

    assert_select "turbo-frame#albums"
    assert_select "form[data-turbo-frame=albums]"
  end
end
