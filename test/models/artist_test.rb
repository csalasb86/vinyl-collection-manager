require "test_helper"

class ArtistTest < ActiveSupport::TestCase
  def setup
    @artist = Artist.new(name: "Test Artist")
  end

  test "should be valid with valid attributes" do
    assert @artist.valid?
  end

  test "should require name" do
    @artist.name = nil
    assert_not @artist.valid?
    assert_includes @artist.errors[:name], "can't be blank"
  end

  test "should require unique discogs_id when present" do
    artist1 = Artist.create!(name: "Artist 1", discogs_id: 123)
    @artist.discogs_id = 123
    assert_not @artist.valid?
    assert_includes @artist.errors[:discogs_id], "has already been taken"
  end

  test "should allow nil discogs_id" do
    @artist.discogs_id = nil
    assert @artist.valid?
  end

  test "should have many albums through album_artists" do
    @artist.save!
    album = Album.create!(title: "Test Album")
    @artist.albums << album

    assert_includes @artist.albums, album
  end

  test "should destroy associated album_artists when destroyed" do
    @artist.save!
    album = Album.create!(title: "Test Album")
    album_artist = AlbumArtist.create!(artist: @artist, album: album)

    assert_difference "AlbumArtist.count", -1 do
      @artist.destroy
    end
  end

  test "find_or_create_from_discogs should create new artist" do
    discogs_artist = Struct.new(:id, :name, :profile, :uri).new(
      123,
      "Discogs Artist",
      "Test profile",
      "https://discogs.com/artist/123"
    )

    assert_difference "Artist.count", 1 do
      artist = Artist.find_or_create_from_discogs(discogs_artist)
      assert_equal "Discogs Artist", artist.name
      assert_equal 123, artist.discogs_id
      assert_equal "Test profile", artist.profile
      assert_equal "https://discogs.com/artist/123", artist.discogs_url
    end
  end

  test "find_or_create_from_discogs should find existing artist" do
    existing_artist = Artist.create!(name: "Existing Artist", discogs_id: 123)

    discogs_artist = Struct.new(:id, :name, :profile).new(
      123,
      "Updated Name",
      "Updated profile"
    )

    assert_no_difference "Artist.count" do
      found_artist = Artist.find_or_create_from_discogs(discogs_artist)
      assert_equal existing_artist, found_artist
    end
  end
end
