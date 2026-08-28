require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "locale@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
  end

  test "English is the default" do
    get albums_path

    assert_equal :en, I18n.locale
    assert_match "Search title or artist", response.body
  end

  test "choosing a locale switches the page and sticks for later requests" do
    get albums_path(locale: "es")
    assert_match "Buscar por título o artista", response.body

    # No locale param this time — the choice is remembered in the session.
    get albums_path
    assert_match "Buscar por título o artista", response.body
    assert_no_match "Search title or artist", response.body
  end

  test "an unknown locale is ignored rather than blowing up" do
    get albums_path(locale: "klingon")

    assert_response :success
    assert_match "Search title or artist", response.body
  end

  test "the picker offers every available locale and marks the current one" do
    get albums_path(locale: "es")

    I18n.available_locales.each do |locale|
      assert_select "a[href*=?]", "locale=#{locale}"
    end
    assert_select "a[aria-current=true]", text: "ES"
  end

  test "Rails' own strings follow the locale too" do
    get albums_path(locale: "es")
    post albums_path, params: { album: { title: "" } }

    assert_response :unprocessable_entity
    assert_match "Título no puede estar en blanco", response.body
  end

  test "the last sync reads as a date, in the chosen language" do
    get albums_path
    assert_match "Never synced", response.body

    @user.update!(discogs_synced_at: 3.hours.ago)

    get albums_path
    assert_match "Last synced about 3 hours ago", response.body

    get albums_path(locale: "es")
    assert_match "Última sincronización hace alrededor de 3 horas", response.body
  end
end
