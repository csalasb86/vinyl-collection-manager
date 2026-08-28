class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :discogs_token, presence: true, if: :discogs_username?
  validates :discogs_username, presence: true, if: :discogs_token?

  def discogs_client
    return nil unless discogs_token.present?

    @discogs_client ||= DiscogsClient.new(discogs_token)
  end

  def authenticate_discogs
    return false unless discogs_client

    begin
      identity = discogs_client.get_identity
      update(discogs_authenticated_at: Time.current) if identity.username.present?
      true
    rescue => e
      Rails.logger.error("Discogs authentication failed: #{e.message}")
      false
    end
  end

  # A sync takes minutes, and with no progress indicator it is natural to click
  # again. Treat one as running until it reports back — or until it is old
  # enough that the process behind it is clearly gone.
  SYNC_ASSUMED_DEAD_AFTER = 30.minutes

  def discogs_syncing?
    discogs_sync_started_at.present? &&
      discogs_sync_started_at > SYNC_ASSUMED_DEAD_AFTER.ago
  end

  def discogs_synced?
    discogs_synced_at.present?
  end

  def discogs_authenticated?
    discogs_authenticated_at.present? && discogs_authenticated_at > 30.days.ago
  end
end
