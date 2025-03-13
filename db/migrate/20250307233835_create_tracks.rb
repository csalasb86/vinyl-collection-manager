class CreateTracks < ActiveRecord::Migration[8.0]
  def change
    create_table :tracks do |t|
      t.references :album, null: false, foreign_key: true
      t.string :title, null: false
      t.string :position, null: false
      t.integer :position_index
      t.string :duration
      
      t.timestamps
    end
    
    add_index :tracks, [:album_id, :position], unique: true
  end
end
