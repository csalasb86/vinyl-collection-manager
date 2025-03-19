class AddDiscogsFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :discogs_username, :string
    add_column :users, :discogs_token, :string
    add_column :users, :discogs_authenticated_at, :datetime

    add_index :users, :discogs_username
  end
end
