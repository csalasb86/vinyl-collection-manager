class DiscogsService
  attr_reader :user, :client
  
  def initialize(user)
    @user = user
    @client = user.discogs_client
  end
  
  def authenticated?
    user.discogs_authenticated?
  end
  
  def search_release(query, options = {})
    client.search(query, options.merge(type: 'release'))
  end
  
  def get_release(discogs_id)
    client.get_release(discogs_id)
  end
  
  def get_user_collection
    client.get_user_collection(user.discogs_username)
  end
  
  def sync_collection
    return unless authenticated?
    
    page = 1
    per_page = 50
    total_pages = 1
    
    created_albums = []
    
    begin
      while page <= total_pages
        collection_items = client.get_user_collection(user.discogs_username, page: page, per_page: per_page)
        total_pages = collection_items.pagination.pages
        
        collection_items.releases.each do |item|
          release = get_release(item.id)
          album = Album.find_or_create_from_discogs(release)
          created_albums << album if album.persisted?
        end
        
        page += 1
      end
      
      { success: true, albums_count: created_albums.size }
    rescue => e
      Rails.logger.error("Failed to sync Discogs collection: #{e.message}")
      { success: false, error: e.message }
    end
  end
end