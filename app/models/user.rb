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

  def discogs_synced?
    discogs_synced_at.present?
  end

  def discogs_authenticated?
    discogs_authenticated_at.present? && discogs_authenticated_at > 30.days.ago
  end
end
