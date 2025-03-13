class DiscogsController < ApplicationController
  def authenticate
    if current_user.discogs_username.blank? || current_user.discogs_token.blank?
      redirect_to edit_user_registration_path, alert: 'Please set your Discogs username and token first.'
      return
    end
    
    if current_user.authenticate_discogs
      redirect_to edit_user_registration_path, notice: 'Successfully authenticated with Discogs.'
    else
      redirect_to edit_user_registration_path, alert: 'Failed to authenticate with Discogs. Please check your credentials.'
    end
  end
end