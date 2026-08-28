class NormalizeUnknownAlbumYears < ActiveRecord::Migration[8.0]
  # Discogs returns year: 0 when a release has no known year. Those rows were
  # stored verbatim and rendered as "0" in the collection. NULL is the only
  # value that means "unknown" for an integer column.
  def up
    execute "UPDATE albums SET year = NULL WHERE year < 1"
  end

  def down
    # Not reversible: 0 and NULL both meant "unknown", NULL is the canonical form.
    raise ActiveRecord::IrreversibleMigration
  end
end
