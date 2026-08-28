require "test_helper"

class SyncDiscogsCollectionJobTest < ActiveJob::TestCase
  setup do
    @user = User.create!(
      email: "job@example.com",
      password: "password123",
      password_confirmation: "password123",
      discogs_token: "token",
      discogs_username: "someone",
      discogs_authenticated_at: Time.current
    )
  end

  test "it runs the sync for a connected user" do
    service = Minitest::Mock.new
    service.expect :sync_collection, { success: true, albums_count: 3 }

    DiscogsService.stub :new, service do
      SyncDiscogsCollectionJob.perform_now(@user)
    end

    service.verify
  end

  test "a disconnected user is skipped rather than failing the job" do
    @user.update!(discogs_authenticated_at: nil)

    called = false
    DiscogsService.stub :new, ->(*) { called = true } do
      assert_nil SyncDiscogsCollectionJob.perform_now(@user)
    end

    assert_not called
  end

  test "a failed sync is logged, not raised" do
    service = Minitest::Mock.new
    service.expect :sync_collection, { success: false, error: "Discogs is down" }

    DiscogsService.stub :new, service do
      assert_nothing_raised { SyncDiscogsCollectionJob.perform_now(@user) }
    end

    service.verify
  end
end
