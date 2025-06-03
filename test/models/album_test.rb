require "test_helper"

class AlbumTest < ActiveSupport::TestCase
  fixtures :albums, :artists, :album_artists

  test "#display_artists returns a comma-separated string of artist names" do
    album = albums(:sample_album)
    assert_equal "John, Paul", album.display_artists
  end
end
