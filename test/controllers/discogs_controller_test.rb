require "test_helper"

class DiscogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      discogs_username: "test_user",
      discogs_token: "test_token"
    )
    sign_in @user
  end

  test "should authenticate with valid credentials" do
    # Test successful authentication by setting up valid response
    @user.update!(discogs_authenticated_at: Time.current)

    # Mock the authenticate_discogs method to return true
    User.class_eval do
      alias_method :original_authenticate_discogs, :authenticate_discogs
      define_method(:authenticate_discogs) { true }
    end

    post authenticate_discogs_url
    assert_redirected_to edit_user_registration_url
    assert_equal "Successfully authenticated with Discogs.", flash[:notice]

    # Restore original method
    User.class_eval do
      alias_method :authenticate_discogs, :original_authenticate_discogs
    end
  end

  test "should fail authentication with invalid credentials" do
    # Mock the authenticate_discogs method to return false
    User.class_eval do
      alias_method :original_authenticate_discogs, :authenticate_discogs
      define_method(:authenticate_discogs) { false }
    end

    post authenticate_discogs_url
    assert_redirected_to edit_user_registration_url
    assert_match(/Failed to authenticate/, flash[:alert])

    # Restore original method
    User.class_eval do
      alias_method :authenticate_discogs, :original_authenticate_discogs
    end
  end

  test "should redirect when missing discogs username" do
    @user.update_columns(discogs_username: nil)

    post authenticate_discogs_url
    assert_redirected_to edit_user_registration_url
    assert_match(/set your Discogs username and token first/, flash[:alert])
  end

  test "should redirect when missing discogs token" do
    @user.update_columns(discogs_token: nil)

    post authenticate_discogs_url
    assert_redirected_to edit_user_registration_url
    assert_match(/set your Discogs username and token first/, flash[:alert])
  end

  test "should redirect when missing both discogs credentials" do
    @user.update_columns(discogs_username: nil, discogs_token: nil)

    post authenticate_discogs_url
    assert_redirected_to edit_user_registration_url
    assert_match(/set your Discogs username and token first/, flash[:alert])
  end

  private

  def sign_in(user)
    post user_session_url, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
