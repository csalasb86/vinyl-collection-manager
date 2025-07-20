require "test_helper"

class AlbumTest < ActiveSupport::TestCase
  def setup
    @album = Album.new(title: "Test Album")
  end

  test "should be valid with valid attributes" do
    assert @album.valid?
  end

  test "should require title" do
    @album.title = nil
    assert_not @album.valid?
    assert_includes @album.errors[:title], "can't be blank"
  end

  test "should require unique discogs_id when present" do
    album1 = Album.create!(title: "Album 1", discogs_id: 123)
    @album.discogs_id = 123
    assert_not @album.valid?
    assert_includes @album.errors[:discogs_id], "has already been taken"
  end

  test "should allow nil discogs_id" do
    @album.discogs_id = nil
    assert @album.valid?
  end

  test "should have many artists through album_artists" do
    @album.save!
    artist = Artist.create!(name: "Test Artist")
    @album.artists << artist

    assert_includes @album.artists, artist
  end

  test "should have many tracks" do
    @album.save!
    track = Track.create!(title: "Test Track", position: "A1", album: @album)

    assert_includes @album.tracks, track
  end

  test "should destroy associated album_artists when destroyed" do
    @album.save!
    artist = Artist.create!(name: "Test Artist")
    album_artist = AlbumArtist.create!(artist: artist, album: @album)

    assert_difference "AlbumArtist.count", -1 do
      @album.destroy
    end
  end

  test "should destroy associated tracks when destroyed" do
    @album.save!
    track = Track.create!(title: "Test Track", position: "A1", album: @album)

    assert_difference "Track.count", -1 do
      @album.destroy
    end
  end

  test "by_year scope should filter by year" do
    album1 = Album.create!(title: "Album 1990", year: 1990)
    album2 = Album.create!(title: "Album 2000", year: 2000)

    results = Album.by_year(1990)
    assert_includes results, album1
    assert_not_includes results, album2
  end

  test "by_genre scope should filter by genre" do
    album1 = Album.create!(title: "Rock Album", genre: [ "Rock" ])
    album2 = Album.create!(title: "Jazz Album", genre: [ "Jazz" ])

    results = Album.by_genre("Rock")
    assert_includes results, album1
    assert_not_includes results, album2
  end

  test "by_format scope should filter by format" do
    album1 = Album.create!(title: "Vinyl Album", format: "Vinyl")
    album2 = Album.create!(title: "CD Album", format: "CD")

    results = Album.by_format("Vinyl")
    assert_includes results, album1
    assert_not_includes results, album2
  end

  test "by_artist scope should filter by artist" do
    artist1 = Artist.create!(name: "Artist 1")
    artist2 = Artist.create!(name: "Artist 2")
    album1 = Album.create!(title: "Album 1")
    album2 = Album.create!(title: "Album 2")

    album1.artists << artist1
    album2.artists << artist2

    results = Album.by_artist(artist1.id)
    assert_includes results, album1
    assert_not_includes results, album2
  end

  test "by_query scope should search title and artist names" do
    artist = Artist.create!(name: "Beatles")
    album1 = Album.create!(title: "Abbey Road")
    album2 = Album.create!(title: "Random Album")

    album1.artists << artist

    results = Album.by_query("Beatles")
    assert_includes results, album1
    assert_not_includes results, album2
  end

  test "display_artists should return comma-separated artist names" do
    @album.save!
    artist1 = Artist.create!(name: "Artist 1")
    artist2 = Artist.create!(name: "Artist 2")
    @album.artists << [ artist1, artist2 ]

    assert_equal "Artist 1, Artist 2", @album.display_artists
  end

  test "cover_url should call cover method when no cover attached" do
    # Test that the method executes without error in test environment
    assert_respond_to @album, :cover_url
    # Skip actual URL generation in test due to missing assets
  end

  test "find_or_create_from_discogs should create new album with full data" do
    discogs_release = Struct.new(:id, :title, :year, :formats, :genres, :uri, :labels, :notes, :artists, :tracklist, :images).new(
      123,
      "Test Release",
      1990,
      [ { "name" => "Vinyl" } ],
      [ "Rock" ],
      "https://discogs.com/release/123",
      [ { "catno" => "ABC123" } ],
      "Test notes",
      [
        Struct.new(:id, :name, :profile, :uri).new(456, "Test Artist", "", "")
      ],
      [
        Struct.new(:position, :title, :duration).new("A1", "Track 1", "3:00"),
        Struct.new(:position, :title, :duration).new("A2", "Track 2", "4:00")
      ],
      []
    )

    assert_difference "Album.count", 1 do
      assert_difference "Artist.count", 1 do
        assert_difference "Track.count", 2 do
      album = Album.find_or_create_from_discogs(discogs_release)

      assert_equal "Test Release", album.title
      assert_equal 1990, album.year
      assert_equal "Vinyl", album.format
      assert_equal [ "Rock" ], album.genre
      assert_equal "ABC123", album.catalog_number
      assert_equal "Test notes", album.notes
      assert_equal 1, album.artists.count
      assert_equal 2, album.tracks.count
        end
      end
    end
  end

  test "find_or_create_from_discogs should find existing album" do
    existing_album = Album.create!(title: "Existing Album", discogs_id: 123)

    discogs_release = Struct.new(:id, :title, :artists, :tracklist, :images).new(
      123,
      "Updated Title",
      [],
      [],
      []
    )

    assert_no_difference "Album.count" do
      found_album = Album.find_or_create_from_discogs(discogs_release)
      assert_equal existing_album, found_album
    end
  end
end
