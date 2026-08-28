require "application_system_test_case"

class CollectionSystemTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "crate@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @coltrane = Artist.create!(name: "John Coltrane")
    Album.create!(title: "Blue Train", year: 1957, format: "LP", genre: [ "Jazz" ])
      .artists << @coltrane
    Album.create!(title: "Remain in Light", year: 1980, format: "LP", genre: [ "Rock" ])

    visit new_user_session_path
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    find("input[type=submit]").click
    assert_no_current_path new_user_session_path, wait: 5
  end

  # The toolbar lives outside the turbo frame precisely so this holds: replacing
  # it on each keystroke would pull the caret out of the field.
  test "searching filters the grid without losing focus on the field" do
    visit albums_path
    assert_text "Remain in Light"

    fill_in "q", with: "Blue"

    assert_no_text "Remain in Light"
    assert_text "Blue Train"
    assert_equal "q", page.evaluate_script("document.activeElement.name")
  end

  test "the search lands in the address bar so the filtered view can be shared" do
    visit albums_path

    fill_in "q", with: "Coltrane"
    assert_text "Blue Train"

    assert_current_path(/q=Coltrane/)
    # Unset filters stay out of the URL.
    assert_no_current_path(/genre=&/)
  end

  test "a chip removes its filter and resets the field it came from" do
    visit albums_path(q: "Blue")
    assert_text "Blue Train"

    find("a[aria-label='Remove filter Search: Blue']").click

    assert_text "Remain in Light"
    assert_equal "", find("input[name=q]").value
  end

  test "choosing a filter applies it and shows it as a chip" do
    visit albums_path

    find("details summary").click
    select "Jazz", from: "genre"

    assert_text "Blue Train"
    assert_no_text "Remain in Light"
    assert_selector "a[aria-label='Remove filter Genre: Jazz']"
  end

  test "the filter panel never pushes the page sideways" do
    [ 1400, 768, 390 ].each do |width|
      page.driver.browser.manage.window.resize_to(width, 900)
      visit albums_path
      find("details summary").click

      overflow = page.evaluate_script(
        "document.documentElement.scrollWidth - document.documentElement.clientWidth"
      )
      assert_equal 0, overflow, "the filter panel overflows the viewport at #{width}px"
    end
  end
end
