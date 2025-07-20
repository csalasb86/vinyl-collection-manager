require "test_helper"

class DiscogsServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      discogs_token: "test_token",
      discogs_username: "test_user",
      discogs_authenticated_at: Time.current
    )
    @service = DiscogsService.new(@user)
  end

  test "should initialize with user and client" do
    assert_equal @user, @service.user
    assert_equal @user.discogs_client, @service.client
  end

  test "authenticated? should return user authentication status" do
    assert @service.authenticated?

    @user.update!(discogs_authenticated_at: nil)
    service = DiscogsService.new(@user)
    assert_not service.authenticated?
  end

  test "search_release should call client with type release" do
    mock_client = Minitest::Mock.new
    mock_client.expect :search, [], [ "test query", { type: "release", per_page: 10 } ]

    @service.stub :client, mock_client do
      @service.search_release("test query", per_page: 10)
    end

    mock_client.verify
    assert true # Add assertion to satisfy test requirement
  end

  test "get_release should call client get_release" do
    mock_client = Minitest::Mock.new
    mock_client.expect :get_release, Struct.new(:id).new(123), [ 123 ]

    @service.stub :client, mock_client do
      result = @service.get_release(123)
      assert_equal 123, result.id
    end

    mock_client.verify
  end

  test "get_user_collection should call client with username" do
    mock_client = Minitest::Mock.new
    mock_client.expect :get_user_collection, [], [ "test_user" ]

    @service.stub :client, mock_client do
      @service.get_user_collection
    end

    mock_client.verify
    assert true # Add assertion to satisfy test requirement
  end

  test "sync_collection should return early if not authenticated" do
    @user.update!(discogs_authenticated_at: nil)
    service = DiscogsService.new(@user)

    result = service.sync_collection
    assert_nil result
  end

  test "sync_collection should return success format" do
    # Test basic sync_collection behavior
    result = @service.sync_collection
    assert_kind_of Hash, result
    assert result.key?(:success)
  end

  test "sync_collection should handle exceptions and return error" do
    # Test error handling without complex mocking
    @user.update!(discogs_authenticated_at: Time.current)
    service = DiscogsService.new(@user)

    # Stub the client to raise an error
    service.stub :client, nil do
      result = service.sync_collection
      assert_not result[:success]
      assert_includes result[:error], "undefined method"
    end
  end

  test "sync_collection should check authentication" do
    # Test that sync_collection respects authentication
    @user.update!(discogs_authenticated_at: nil)
    service = DiscogsService.new(@user)

    result = service.sync_collection
    assert_nil result
  end
end
