require "test_helper"

class AccessibilityTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "a11y@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @album = Album.create!(title: "Blue Train", year: 1957, format: "LP")
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
  end

  # The old flash was a plain div: a screen reader never announced it, it could
  # not be dismissed, and it pushed the page down on arrival.
  test "a notice is announced politely and can be dismissed" do
    get albums_path

    assert_select "[role=status].toast-ok" do
      assert_select "button[data-action='toast#dismiss'][aria-label]"
    end
    assert_select "[role=status][data-toast-dismiss-after-value]"
  end

  test "an error interrupts and never disappears on its own" do
    # No Discogs credentials, so this redirects back with an alert.
    patch refresh_from_discogs_album_path(@album)
    follow_redirect!

    assert_select "[role=alert].toast-error"
    assert_select "[role=alert][data-toast-dismiss-after-value]", false,
                  "an error the user still has to act on must not time out"
  end

  test "the toast region floats instead of pushing the page" do
    get albums_path

    assert_select "div.toast-region"
  end

  test "every page offers a skip link before anything else" do
    [ albums_path, album_path(@album), new_album_path, search_discogs_albums_path ].each do |path|
      get path

      assert_select "a.skip-link[href='#main']", 1, "no skip link on #{path}"
      assert_select "main#main", 1, "no main landmark on #{path}"
    end
  end

  test "images carry an alt that names the record, and decoration is hidden" do
    @album.cover.attach(
      io: StringIO.new(file_fixture("cover.png").read),
      filename: "cover.png",
      content_type: "image/png"
    )

    get album_path(@album)

    assert_select "img[alt=?]", "Cover of Blue Train"
    assert_select "img[aria-hidden=true][alt='']", 1, "the blurred backdrop must be hidden from readers"
  end

  test "form controls are labelled" do
    get new_album_path

    %w[album_title album_year album_format album_catalog_number album_notes].each do |id|
      assert_select "label[for=?]", id, 1, "#{id} has no label"
    end
  end

  test "the collection search field is labelled even though the label is visual noise" do
    get albums_path

    assert_select "span.sr-only", text: "Search the collection"
    assert_select "label[for=sort]"
  end
end
