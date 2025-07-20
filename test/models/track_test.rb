require "test_helper"

class TrackTest < ActiveSupport::TestCase
  def setup
    @album = Album.create!(title: "Test Album")
    @track = Track.new(
      title: "Test Track",
      position: "A1",
      album: @album
    )
  end

  test "should be valid with valid attributes" do
    assert @track.valid?
  end

  test "should require title" do
    @track.title = nil
    assert_not @track.valid?
    assert_includes @track.errors[:title], "can't be blank"
  end

  test "should require position" do
    @track.position = nil
    assert_not @track.valid?
    assert_includes @track.errors[:position], "can't be blank"
  end

  test "should belong to album" do
    assert_equal @album, @track.album
  end

  test "should be ordered by position_index by default" do
    track1 = Track.create!(title: "Track 1", position: "A1", album: @album, position_index: 2)
    track2 = Track.create!(title: "Track 2", position: "A2", album: @album, position_index: 1)

    tracks = Track.all
    assert_equal track2, tracks.first
    assert_equal track1, tracks.second
  end

  test "should allow optional duration" do
    @track.duration = "3:45"
    assert @track.valid?
  end

  test "should allow optional position_index" do
    @track.position_index = 1
    assert @track.valid?
  end
end
