require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Warden::Test::Helpers
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
    Warden.test_mode!
    resize_window_to(*DEFAULT_WINDOW)
  end

  teardown do
    Warden.test_reset!
  end

  def resize_window_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  # Signing in through the form in every setup was the suite's main source of
  # flakiness: Selenium occasionally dropped the keystrokes, the password field
  # stayed empty and the browser's own required-field check blocked the submit
  # without a word. Warden puts the session in place directly. The login form
  # itself is still covered, once, by its own test.
  def sign_in_as(user)
    login_as(user, scope: :user)
  end

  # For the test that exercises the real form.
  def sign_in_through_the_form(user, password: "password123")
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    find("input[type=submit]").click

    assert_selector "nav button[data-controller=theme]", wait: 10
  end
end
