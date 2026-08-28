class AddLocaleToUsers < ActiveRecord::Migration[8.0]
  # Persisted on the user, not just the session, so background jobs can address
  # someone in the language they actually chose.
  def change
    add_column :users, :locale, :string
  end
end
