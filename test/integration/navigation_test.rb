require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "navigation@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
  end

  test "the mobile menu exists and is wired to its toggle" do
    get albums_path

    assert_select "#mobile-menu[data-drawer-target=panel]", 1
    assert_select "button[data-action='drawer#toggle'][aria-controls=mobile-menu][aria-expanded=false]", 1
  end

  test "every destination stays reachable inside the mobile menu" do
    get albums_path

    within_mobile_menu do |menu|
      assert_includes menu, albums_path
      assert_includes menu, search_discogs_albums_path
      assert_includes menu, edit_user_registration_path
      assert_includes menu, sync_collection_albums_path
      assert_includes menu, destroy_user_session_path
    end
  end

  test "the current section is announced, not just painted" do
    get albums_path
    assert_select "a[href=?][aria-current=page]", albums_path

    get search_discogs_albums_path
    assert_select "a[href=?][aria-current=page]", search_discogs_albums_path
    assert_select "a[href=?][aria-current=page]", albums_path, false
  end

  test "syncing is a confirmed POST, never a bare link" do
    get albums_path

    assert_select "form[action=?][method=post]", sync_collection_albums_path
    assert_select "form[action=?] button[data-turbo-confirm]", sync_collection_albums_path
    assert_select "a[href=?]", sync_collection_albums_path, false,
                  "a one-click link would fire a full collection sync by accident"
  end

  test "the account menu holds the email instead of the bar" do
    get albums_path

    assert_select "[data-controller=dropdown] [data-dropdown-target=menu]" do
      assert_select "p", text: @user.email
    end
    assert_select "button[data-dropdown-target=button][aria-expanded=false][aria-haspopup=menu]", 1
  end

  test "the Discogs state reads as text, not only as a colour" do
    get albums_path
    assert_match "Discogs not connected", response.body

    @user.update!(discogs_token: "t", discogs_username: "u", discogs_authenticated_at: Time.current)
    get albums_path
    assert_match "Discogs connected", response.body
  end

  private

  def within_mobile_menu
    menu = response.body[/<div id="mobile-menu".*?\n  <\/div>/m]
    assert menu, "mobile menu not found in the page"
    yield menu
  end
end
