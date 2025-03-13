class CreateAlbums < ActiveRecord::Migration[8.0]
  def change
    create_table :albums do |t|
      t.string :title, null: false
      t.integer :year
      t.string :format
      t.string :catalog_number
      t.text :notes
      t.string :genre, array: true, default: []
      t.integer :discogs_id
      t.string :discogs_url

      t.timestamps
    end

    add_index :albums, :title
    add_index :albums, :year
    add_index :albums, :format
    add_index :albums, :genre, using: 'gin'
    add_index :albums, :discogs_id, unique: true
  end
end
