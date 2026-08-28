require "test_helper"

class DiscogsClientTest < ActiveSupport::TestCase
  def build_client(&block)
    stubs = Faraday::Adapter::Test::Stubs.new(&block)
    connection = Faraday.new(url: DiscogsClient::BASE_URL) do |f|
      f.adapter :test, stubs
    end
    [ DiscogsClient.new("test_token", connection: connection), stubs ]
  end

  test "search hits /database/search with query and options" do
    client, stubs = build_client do |stub|
      stub.get("/database/search?per_page=10&q=abbey+road&type=release") do
        [ 200, {}, { results: [ { id: 1, title: "Abbey Road", format: [ "Vinyl", "LP" ] } ],
                     pagination: { page: 1, pages: 3 } }.to_json ]
      end
    end

    results = client.search("abbey road", type: "release", per_page: 10)

    assert_equal 1, results.results.first.id
    assert_equal "Abbey Road", results.results.first.title
    assert_equal [ "Vinyl", "LP" ], results.results.first.format
    assert_equal 3, results.pagination.pages
    stubs.verify_stubbed_calls
  end

  test "get_release returns nested method access compatible with album import" do
    client, stubs = build_client do |stub|
      stub.get("/releases/123") do
        [ 200, {}, {
          id: 123, title: "Kind of Blue", year: 1959, uri: "https://discogs.com/r/123",
          formats: [ { name: "Vinyl" } ], genres: [ "Jazz" ],
          labels: [ { catno: "CL 1355" } ],
          artists: [ { id: 9, name: "Miles Davis" } ],
          tracklist: [ { position: "A1", title: "So What", duration: "9:22" } ],
          images: [ { type: "primary", uri: "https://img/123.jpg" } ]
        }.to_json ]
      end
    end

    release = client.get_release(123)

    assert_equal "Kind of Blue", release.title
    assert_equal "Vinyl", release.formats&.first&.dig("name")
    assert_equal "CL 1355", release.labels&.first&.dig("catno")
    assert_equal "So What", release.tracklist.first.title
    assert_equal "primary", release.images.first.type
    stubs.verify_stubbed_calls
  end

  test "get_user_collection paginates through folder 0" do
    client, stubs = build_client do |stub|
      stub.get("/users/carlos/collection/folders/0/releases?page=2&per_page=50") do
        [ 200, {}, { pagination: { page: 2, pages: 2 },
                     releases: [ { id: 55 } ] }.to_json ]
      end
    end

    collection = client.get_user_collection("carlos", page: 2, per_page: 50)

    assert_equal 2, collection.pagination.pages
    assert_equal 55, collection.releases.first.id
    stubs.verify_stubbed_calls
  end

  test "get_identity returns username" do
    client, stubs = build_client do |stub|
      stub.get("/oauth/identity") { [ 200, {}, { username: "carlos" }.to_json ] }
    end

    assert_equal "carlos", client.get_identity.username
    stubs.verify_stubbed_calls
  end

  test "raises DiscogsClient::Error with API message on failure" do
    client, _stubs = build_client do |stub|
      stub.get("/releases/999") { [ 401, {}, { message: "Invalid token" }.to_json ] }
    end

    error = assert_raises(DiscogsClient::Error) { client.get_release(999) }
    assert_match "401", error.message
    assert_match "Invalid token", error.message
  end

  test "retries once after 429 honoring Retry-After" do
    calls = 0
    client, _stubs = build_client do |stub|
      stub.get("/releases/123") do
        calls += 1
        if calls == 1
          [ 429, { "Retry-After" => "0" }, { message: "rate limited" }.to_json ]
        else
          [ 200, {}, { id: 123, title: "OK" }.to_json ]
        end
      end
    end

    release = client.get_release(123)

    assert_equal 2, calls
    assert_equal "OK", release.title
  end
end
