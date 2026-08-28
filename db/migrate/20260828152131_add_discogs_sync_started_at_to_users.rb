class AddDiscogsSyncStartedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :discogs_sync_started_at, :datetime
  end
end
