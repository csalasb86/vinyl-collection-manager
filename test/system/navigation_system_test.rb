require "application_system_test_case"

# Regression cover for the navigation bug: below 768px every link lived inside
# a `hidden md:block` wrapper with no menu to reveal it, so a phone had no way
# out of the first screen.
class NavigationSystemTest < ApplicationSystemTestCase
  PHONE = [ 390, 844 ].freeze
  DESKTOP = [ 1400, 900 ].freeze

  setup do
    @user = User.create!(
      email: "phone@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    sign_in_as(@user)
  end

  test "a phone can reach the rest of the app through the menu" do
    resize_window_to(*PHONE)
    visit albums_path

    # Closed by default, and the desktop links really are out of reach.
    assert_selector "button[aria-expanded=false][aria-controls=mobile-menu]"
    assert_no_selector "#mobile-menu a", visible: true

    find("button[aria-controls=mobile-menu]").click

    assert_selector "button[aria-expanded=true][aria-controls=mobile-menu]"
    within "#mobile-menu" do
      assert_link "Collection"
      assert_link "Search Discogs"
      assert_link "Account"
      assert_button "Log out"
    end
  end

  test "a link in the menu navigates and the menu does not stay open" do
    resize_window_to(*PHONE)
    visit albums_path

    find("button[aria-controls=mobile-menu]").click
    within("#mobile-menu") { click_on "Search Discogs" }

    assert_current_path search_discogs_albums_path
    assert_selector "button[aria-expanded=false][aria-controls=mobile-menu]"
  end

  # `hidden` is an HTMLElement property, so assigning it on an <svg> is a no-op:
  # the icon silently never swapped. Both toggles go through the attribute now.
  test "the menu button swaps its icon between the bars and the cross" do
    resize_window_to(*PHONE)
    visit albums_path

    assert_selector "[data-drawer-target=iconOpen]", visible: true
    assert_no_selector "[data-drawer-target=iconClose]", visible: true

    find("button[aria-controls=mobile-menu]").click

    assert_no_selector "[data-drawer-target=iconOpen]", visible: true
    assert_selector "[data-drawer-target=iconClose]", visible: true
  end

  test "the theme button swaps between the sun and the moon" do
    resize_window_to(*DESKTOP)
    visit albums_path

    assert_selector "[data-theme-target=iconLight]", visible: true
    assert_no_selector "[data-theme-target=iconDark]", visible: true

    find("button[data-controller=theme]").click

    assert_no_selector "[data-theme-target=iconLight]", visible: true
    assert_selector "[data-theme-target=iconDark]", visible: true
    assert_text "Dark"
  end

  test "escape closes the menu" do
    resize_window_to(*PHONE)
    visit albums_path

    find("button[aria-controls=mobile-menu]").click
    assert_selector "button[aria-expanded=true][aria-controls=mobile-menu]"

    find("body").send_keys(:escape)

    assert_selector "button[aria-expanded=false][aria-controls=mobile-menu]"
  end

  test "the account menu opens on desktop and closes on an outside click" do
    resize_window_to(*DESKTOP)
    visit albums_path

    assert_no_selector "[data-dropdown-target=menu]", visible: true

    find("button[data-dropdown-target=button]").click
    assert_selector "[data-dropdown-target=menu]", visible: true
    assert_text @user.email

    find("#main").click

    assert_no_selector "[data-dropdown-target=menu]", visible: true
  end

  test "the theme survives a full page load" do
    resize_window_to(*DESKTOP)
    visit albums_path

    find("button[data-controller=theme]").click
    assert_selector "html[data-theme=dark]"

    visit albums_path

    assert_selector "html[data-theme=dark]", visible: :all
  end

  # setup just signed in, so the landing page still carries that notice — a
  # later visit would have consumed the flash already.
  test "a notice can be dismissed" do
    assert_selector "[role=status]", text: "Signed in successfully"

    find("[role=status] button[data-action='toast#dismiss']").click

    assert_no_selector "[role=status]"
  end

  test "the toast floats over the page instead of pushing it down" do
    assert_selector ".toast-region"

    position = page.evaluate_script(
      "getComputedStyle(document.querySelector('.toast-region')).position"
    )
    assert_equal "fixed", position
  end
end
