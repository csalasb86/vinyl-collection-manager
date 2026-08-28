# Importing a Discogs collection is one API call per release against a 60
# requests/minute limit, so a few hundred records take minutes. Run inline it
# held a web request open well past any sane proxy timeout.
class SyncDiscogsCollectionJob < ApplicationJob
  queue_as :default

  def perform(user)
    return user.update_column(:discogs_sync_started_at, nil) unless user.discogs_authenticated?

    result = DiscogsService.new(user).sync_collection

    if result[:success]
      user.update_column(:discogs_synced_at, Time.current)
      Rails.logger.info("Discogs sync finished for user #{user.id}: #{result[:albums_count]} albums")
      announce(user, :ok, t(user, "vinyl_collection.sync.finished", count: result[:albums_count]))
    else
      Rails.logger.error("Discogs sync failed for user #{user.id}: #{result[:error]}")
      announce(user, :error, t(user, "vinyl_collection.sync.failed", error: result[:error]))
    end

    result
  ensure
    # Released whatever happened, so a crash cannot leave syncing wedged on.
    user.update_column(:discogs_sync_started_at, nil)
  end

  private

  # The job has no request, so the language comes off the user record rather
  # than the session.
  def t(user, key, **args)
    I18n.t(key, locale: user.locale.presence || I18n.default_locale, **args)
  end

  # Pushes a toast onto whatever pages this user has open, so a sync that
  # finishes minutes later still reports back.
  def announce(user, kind, message)
    Turbo::StreamsChannel.broadcast_append_to(
      user,
      target: "toasts",
      partial: "shared/toast",
      locals: { kind: kind, message: message, dismiss_after: (kind == :ok ? 10_000 : nil) }
    )
  rescue => e
    Rails.logger.warn("Could not broadcast sync result to user #{user.id}: #{e.message}")
  end
end
