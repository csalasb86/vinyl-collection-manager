require "test_helper"

class AlbumArtistTest < ActiveSupport::TestCase
  def setup
    @artist = Artist.create!(name: "Test Artist")
    @album = Album.create!(title: "Test Album")
    @album_artist = AlbumArtist.new(artist: @artist, album: @album)
  end

  test "should be valid with valid attributes" do
    assert @album_artist.valid?
  end

  test "should belong to artist" do
    assert_equal @artist, @album_artist.artist
  end

  test "should belong to album" do
    assert_equal @album, @album_artist.album
  end

  test "should require unique combination of album and artist" do
    @album_artist.save!

    duplicate = AlbumArtist.new(artist: @artist, album: @album)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:album_id], "has already been taken"
  end

  test "should allow same artist with different albums" do
    @album_artist.save!

    another_album = Album.create!(title: "Another Album")
    another_album_artist = AlbumArtist.new(artist: @artist, album: another_album)
    assert another_album_artist.valid?
  end

  test "should allow same album with different artists" do
    @album_artist.save!

    another_artist = Artist.create!(name: "Another Artist")
    another_album_artist = AlbumArtist.new(artist: another_artist, album: @album)
    assert another_album_artist.valid?
  end
end
