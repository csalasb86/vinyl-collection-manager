require "test_helper"

class ThemeTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "theme@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
  end

  test "the theme is applied before first paint to avoid a flash of the wrong palette" do
    get albums_path

    assert_response :success
    # Inline, in the head, and ahead of the stylesheet — otherwise it flashes.
    assert_match(/localStorage\.getItem\("theme"\)/, response.body)
    assert_match(/document\.documentElement\.dataset\.theme/, response.body)

    head_html = response.body[/<head>.*<\/head>/m]
    assert_includes head_html, "dataset.theme", "the theme script must live in the head"
    # The tailwind link is skipped in test, so order against the font stylesheet,
    # which is the first CSS the head loads in every environment.
    assert_operator head_html.index("dataset.theme"), :<, head_html.index("fonts.googleapis.com"),
                    "the theme script must run before any stylesheet loads"
  end

  test "the theme toggle is wired to the Stimulus controller" do
    get albums_path

    assert_select "button[data-controller=theme][data-action='click->theme#toggle']", 1
    assert_select "[data-theme-target=label]", 1
    assert_select "[data-theme-target=iconLight]", 1
    assert_select "[data-theme-target=iconDark]", 1
  end

  test "the first tab stop skips to the main content" do
    get albums_path

    assert_select "a.skip-link[href='#main']", 1
    assert_select "main#main", 1
  end

  test "views carry no literal Tailwind colors, only semantic tokens" do
    literal = Dir.glob("app/views/**/*.erb")
      .reject { |f| f.include?("mailer") }
      .flat_map { |f| File.read(f).scan(/\b(?:bg|text|border|ring)-(?:white|black|gray|blue|green|red|yellow|purple)-?\d{0,3}\b/) }
      .uniq

    assert_empty literal,
                 "these must go through the token layer so dark mode works: #{literal.join(', ')}"
  end
end
