class BackfillDiscogsSyncedAt < ActiveRecord::Migration[8.0]
  # discogs_synced_at is new, so everyone who had already imported a collection
  # read as "Never synced". There is no record of when those syncs ran, so
  # approximate from the newest album that came from Discogs — closer to the
  # truth than claiming it never happened.
  def up
    execute <<~SQL
      UPDATE users
      SET discogs_synced_at = (
        SELECT MAX(created_at) FROM albums WHERE discogs_id IS NOT NULL
      )
      WHERE discogs_username IS NOT NULL
        AND discogs_synced_at IS NULL
        AND EXISTS (SELECT 1 FROM albums WHERE discogs_id IS NOT NULL)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
