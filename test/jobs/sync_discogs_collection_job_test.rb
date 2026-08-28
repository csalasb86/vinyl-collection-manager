require "test_helper"
require "turbo/broadcastable/test_helper"

class SyncDiscogsCollectionJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper
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

  # The sync answers minutes after the click, so the only way the user hears
  # about it is this broadcast.
  test "a finished sync is announced to the user's open pages" do
    service = Minitest::Mock.new
    service.expect :sync_collection, { success: true, albums_count: 42 }

    assert_turbo_stream_broadcasts(@user, count: 1) do
      DiscogsService.stub :new, service do
        SyncDiscogsCollectionJob.perform_now(@user)
      end
    end
  end

  test "a failed sync is announced too, rather than leaving the user waiting" do
    service = Minitest::Mock.new
    service.expect :sync_collection, { success: false, error: "Discogs is down" }

    assert_turbo_stream_broadcasts(@user, count: 1) do
      DiscogsService.stub :new, service do
        SyncDiscogsCollectionJob.perform_now(@user)
      end
    end
  end

  test "the announcement speaks the language the user chose" do
    @user.update!(locale: "es")
    service = Minitest::Mock.new
    service.expect :sync_collection, { success: true, albums_count: 2 }

    broadcasts = capture_turbo_stream_broadcasts(@user) do
      DiscogsService.stub :new, service do
        SyncDiscogsCollectionJob.perform_now(@user)
      end
    end

    assert_match "Se importaron 2 discos", broadcasts.first.to_s
  end

  test "a sync completion stamps the time so the UI can report it" do
    service = Minitest::Mock.new
    service.expect :sync_collection, { success: true, albums_count: 1 }

    assert_nil @user.discogs_synced_at
    DiscogsService.stub :new, service do
      SyncDiscogsCollectionJob.perform_now(@user)
    end

    assert_not_nil @user.reload.discogs_synced_at
  end
end
