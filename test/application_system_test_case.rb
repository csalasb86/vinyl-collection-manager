require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--remote-debugging-port=9222")
  end

  DEFAULT_WINDOW = [ 1400, 900 ].freeze

  # The browser is reused across tests, so a test that resizes the window leaks
  # that viewport into whatever runs next. Start every test from a known size.
  setup do
    resize_window_to(*DEFAULT_WINDOW)
  end

  def resize_window_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  # Signing in is a full page load. Waiting on the *absence* of the sign-in path
  # can pass before that load finishes, which made the suite flaky once several
  # files were signing in. Wait on something only the signed-in shell renders.
  def sign_in_as(user, password: "password123")
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    find("input[type=submit]").click

    assert_selector "nav button[data-controller=theme]", wait: 10
  end
end
