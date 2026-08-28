class AddDiscogsSyncedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :discogs_synced_at, :datetime
  end
end
