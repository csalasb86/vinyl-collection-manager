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

  # Anything a Stimulus controller writes has to be handed to it from the view;
  # a string baked into the JS would stay English whatever the locale.
  test "labels written by JavaScript are handed over translated" do
    get albums_path(locale: "es")

    assert_select "button[data-controller=theme][data-theme-light-label-value=?]", "Claro"
    assert_select "button[data-controller=theme][data-theme-dark-label-value=?]", "Oscuro"
    assert_select "nav[data-controller=drawer][data-drawer-open-label-value=?]", "Abrir menú"
    assert_select "nav[data-controller=drawer][data-drawer-close-label-value=?]", "Cerrar menú"
  end

  test "no Stimulus controller carries user-facing English of its own" do
    offenders = Dir.glob("app/javascript/**/*.js").filter_map do |file|
      body = File.read(file)
      # Strings assigned to textContent or an aria-label, not read from a value.
      hits = body.scan(/(?:textContent\s*=|"aria-label",)\s*[^\n]*"[A-Z][a-z][^"]{2,}"/)
      "#{File.basename(file)}: #{hits.join(', ')}" if hits.any?
    end

    assert_empty offenders,
                 "these would stay English in Spanish: #{offenders.join('; ')}"
  end
end
