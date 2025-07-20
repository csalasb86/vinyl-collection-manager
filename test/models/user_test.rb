require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require password" do
    @user.password = nil
    assert_not @user.valid?
    assert_includes @user.errors[:password], "can't be blank"
  end

  test "should validate email format" do
    @user.email = "invalid_email"
    assert_not @user.valid?
    assert_includes @user.errors[:email], "is invalid"
  end

  test "should require unique email" do
    @user.save!
    duplicate_user = User.new(
      email: @user.email,
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should require discogs_token when discogs_username is present" do
    @user.discogs_username = "testuser"
    assert_not @user.valid?
    assert_includes @user.errors[:discogs_token], "can't be blank"
  end

  test "should require discogs_username when discogs_token is present" do
    @user.discogs_token = "test_token"
    assert_not @user.valid?
    assert_includes @user.errors[:discogs_username], "can't be blank"
  end

  test "should be valid with both discogs_token and discogs_username" do
    @user.discogs_token = "test_token"
    @user.discogs_username = "testuser"
    assert @user.valid?
  end

  test "discogs_client should return nil without token" do
    assert_nil @user.discogs_client
  end

  test "discogs_client should return wrapper with token" do
    @user.discogs_token = "test_token"
    client = @user.discogs_client
    assert_instance_of Discogs::Wrapper, client
  end

  test "discogs_authenticated? should return false without authentication date" do
    assert_not @user.discogs_authenticated?
  end

  test "discogs_authenticated? should return true with recent authentication" do
    @user.discogs_authenticated_at = 1.day.ago
    assert @user.discogs_authenticated?
  end

  test "discogs_authenticated? should return false with old authentication" do
    @user.discogs_authenticated_at = 31.days.ago
    assert_not @user.discogs_authenticated?
  end

  test "authenticate_discogs should return false without client" do
    assert_not @user.authenticate_discogs
  end
end
