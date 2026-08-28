# Importing a Discogs collection is one API call per release against a 60
# requests/minute limit, so a few hundred records take minutes. Run inline it
# held a web request open well past any sane proxy timeout.
class SyncDiscogsCollectionJob < ApplicationJob
  queue_as :default

  def perform(user)
    return unless user.discogs_authenticated?

    result = DiscogsService.new(user).sync_collection

    if result[:success]
      Rails.logger.info("Discogs sync finished for user #{user.id}: #{result[:albums_count]} albums")
    else
      Rails.logger.error("Discogs sync failed for user #{user.id}: #{result[:error]}")
    end

    result
  end
end
