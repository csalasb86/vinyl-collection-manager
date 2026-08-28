require "test_helper"

class AlbumDetailTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "detail@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }

    @album = Album.create!(
      title: "Kind of Blue", year: 1959, format: "LP",
      catalog_number: "CL 1355", discogs_id: 1387137,
      discogs_url: "https://www.discogs.com/release/1387137",
      genre: [ "Jazz" ]
    )
    @album.artists << Artist.create!(name: "Miles Davis")
  end

  test "the actions read as a hierarchy, with delete apart from the rest" do
    get album_path(@album)

    # Primary carries the accent fill, the secondary only an outline.
    assert_select "a[href=?].bg-accent", edit_album_path(@album)
    assert_select "a[href=?].border-line", refresh_from_discogs_album_path(@album)
    assert_select "a[href=?].bg-accent", refresh_from_discogs_album_path(@album), false,
                  "refresh must not compete with edit"

    # Destructive is danger-coloured and pushed away from the other two.
    assert_select "form.ml-auto[action=?]", album_path(@album) do
      assert_select "button.text-danger"
      assert_select "button[data-turbo-confirm]"
    end
  end

  test "the tracklist reads in sleeve order, not insertion order" do
    @album.tracks.create!(title: "All Blues", position: "B1", position_index: 4)
    @album.tracks.create!(title: "So What", position: "A1", position_index: 1)
    @album.tracks.create!(title: "Blue in Green", position: "A3", position_index: 3)

    get album_path(@album)

    positions = css_select("tbody tr td:first-child").map { |td| td.text.strip }
    assert_equal [ "A1", "A3", "B1" ], positions
  end

  test "an unknown year reads as Unknown rather than as a blank or a zero" do
    @album.update!(year: nil)

    get album_path(@album)

    assert_select "dd", text: "Unknown"
  end

  test "Discogs BBCode in the notes is unwrapped, not shown raw" do
    @album.update!(notes: "See [url=https://www.discogs.com/release/2506916]2506916[/url] " \
                          "by [a=Miles Davis] on [l=Columbia]. [b]First press.[/b]")

    get album_path(@album)

    assert_match "See 2506916 by Miles Davis on Columbia. First press.", response.body
    assert_no_match(/\[url=/, response.body)
    assert_no_match(/\[\/b\]/, response.body)
  end

  # simple_format sanitizes, so a tag in the notes is stripped rather than
  # escaped. Either way nothing from the notes may end up executable.
  test "markup in the notes never reaches the page as an element" do
    @album.update!(notes: "[b]<script>alert(1)</script>[/b] <img src=x onerror=alert(2)>")

    get album_path(@album)

    notes = css_select("div.break-words").first.to_s
    assert_no_match(/<script/i, notes)
    assert_no_match(/onerror/i, notes)
    assert_match "alert(1)", notes, "the text itself should survive as text"
  end

  test "an album with no cover still names itself in the placeholder" do
    get album_path(@album)

    assert_select "img", false, "this album has no cover attached"
    assert_match "No Cover", response.body
  end
end
