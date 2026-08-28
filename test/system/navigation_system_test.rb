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

  # The controllers write these labels themselves, so they only follow the
  # locale if the view hands them over as Stimulus values.
  test "the theme and menu labels follow the chosen language" do
    resize_window_to(*PHONE)
    visit albums_path(locale: "es")

    theme = find("button[data-controller=theme]")
    assert_equal "Claro", find("[data-theme-target=label]").text
    assert_equal "Cambiar al tema oscuro", theme[:"aria-label"]

    theme.click
    assert_equal "Oscuro", find("[data-theme-target=label]").text
    assert_equal "Cambiar al tema claro", theme[:"aria-label"]

    menu = find("button[aria-controls=mobile-menu]")
    assert_equal "Abrir menú", menu[:"aria-label"]
    menu.click
    assert_equal "Cerrar menú", menu[:"aria-label"]
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

  # Also the one place the real login form is exercised.
  test "signing in through the form announces it in a toast that can be dismissed" do
    logout(:user)
    sign_in_through_the_form(@user)

    assert_selector "[role=status]", text: "Signed in successfully"

    find("[role=status] button[data-action='toast#dismiss']").click

    assert_no_selector "[role=status]"
  end

  test "the toast region floats over the page instead of pushing it down" do
    visit albums_path

    assert_selector ".toast-region"
    position = page.evaluate_script(
      "getComputedStyle(document.querySelector('.toast-region')).position"
    )
    assert_equal "fixed", position
  end

  # The one promise from the design proposal that had never been measured.
  test "every tappable thing is at least 44px tall on a phone" do
    resize_window_to(*PHONE)
    visit albums_path

    find("button[aria-controls=mobile-menu]").click

    small = page.all(
      "nav a, nav button, #mobile-menu a, #mobile-menu button, main .btn, main summary, main select",
      visible: true
    ).filter_map do |el|
      height = el.evaluate_script("Math.round(this.getBoundingClientRect().height)")
      "#{el.text.split("\n").first || el.tag_name} (#{height}px)" if height < 44
    end

    assert_empty small, "under the 44px touch target: #{small.join(', ')}"
  end
end
