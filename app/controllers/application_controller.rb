class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pagy::Frontend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :switch_locale

  protected

  # Kept in the session rather than the URL: this is a personal collection, not
  # something being shared per-language, and it keeps the choice on the Devise
  # pages too, where there is no user record to hang it off yet.
  def switch_locale(&action)
    requested = params[:locale].to_s

    if I18n.available_locales.map(&:to_s).include?(requested)
      session[:locale] = requested
      # Also on the record, so a background job can address this person in the
      # language they picked rather than in the default one.
      current_user&.update_column(:locale, requested)
    end

    I18n.with_locale(session[:locale] || current_user&.locale || I18n.default_locale, &action)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [ :discogs_username, :discogs_token ])
  end
end
