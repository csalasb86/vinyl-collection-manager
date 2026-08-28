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
    service.expect :sync_collection, { success: true, albums_count: 42 }

    result = DiscogsService.stub :new, service do
      SyncDiscogsCollectionJob.perform_now(@user)
    end

    assert_equal 42, result[:albums_count]
    service.verify
  end

  test "a disconnected user is skipped, and does not stay marked as syncing" do
    @user.update!(discogs_authenticated_at: nil, discogs_sync_started_at: Time.current)

    called = false
    DiscogsService.stub :new, ->(*) { called = true } do
      SyncDiscogsCollectionJob.perform_now(@user)
    end

    assert_not called, "no sync should have been attempted"
    assert_nil @user.reload.discogs_sync_started_at
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

  test "the running flag is released even when the sync blows up" do
    @user.update!(discogs_sync_started_at: Time.current)

    DiscogsService.stub :new, ->(*) { raise "Discogs exploded" } do
      assert_raises(RuntimeError) { SyncDiscogsCollectionJob.perform_now(@user) }
    end

    assert_nil @user.reload.discogs_sync_started_at,
               "a crashed sync must not leave the user wedged as syncing"
  end

  test "a finished sync releases the flag" do
    @user.update!(discogs_sync_started_at: Time.current)
    service = Minitest::Mock.new
    service.expect :sync_collection, { success: true, albums_count: 1 }

    DiscogsService.stub :new, service do
      SyncDiscogsCollectionJob.perform_now(@user)
    end

    assert_nil @user.reload.discogs_sync_started_at
  end
end
