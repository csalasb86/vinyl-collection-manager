require "ostruct"

# Minimal Discogs API client using a personal access token.
# Replaces the unmaintained discogs-wrapper gem. Responses are parsed
# into OpenStructs to preserve the method-style access (release.title,
# results.pagination.pages) the rest of the app relies on.
class DiscogsClient
  BASE_URL = "https://api.discogs.com".freeze
  USER_AGENT = "VinylCollectionManager/1.0".freeze

  class Error < StandardError; end

  def initialize(user_token, connection: nil)
    @user_token = user_token
    @connection = connection
  end

  def search(query, options = {})
    get("/database/search", options.merge(q: query))
  end

  def get_release(discogs_id)
    get("/releases/#{discogs_id}")
  end

  def get_user_collection(username, options = {})
    get("/users/#{username}/collection/folders/0/releases", options)
  end

  def get_identity
    get("/oauth/identity")
  end

  private

  def get(path, params = {}, retried: false)
    response = connection.get(path, params)

    # Discogs allows 60 requests/minute per token; honor Retry-After once
    if response.status == 429 && !retried
      sleep((response.headers["Retry-After"] || 60).to_i)
      return get(path, params, retried: true)
    end

    raise Error, "Discogs API error (#{response.status}): #{error_message(response.body)}" unless response.success?

    JSON.parse(response.body, object_class: OpenStruct)
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.headers["User-Agent"] = USER_AGENT
      f.headers["Authorization"] = "Discogs token=#{@user_token}"
    end
  end

  def error_message(body)
    JSON.parse(body)["message"]
  rescue JSON::ParserError, TypeError
    body.to_s.truncate(200)
  end
end
