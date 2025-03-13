class CreateArtists < ActiveRecord::Migration[8.0]
  def change
    create_table :artists do |t|
      t.string :name, null: false
      t.text :profile
      t.integer :discogs_id
      t.string :discogs_url

      t.timestamps
    end

    add_index :artists, :name
    add_index :artists, :discogs_id, unique: true
  end
end
