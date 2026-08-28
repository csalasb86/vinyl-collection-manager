module ApplicationHelper
  include Pagy::Frontend

  # The page ground comes from the base layer (body { background: var(--bg) }),
  # so this only decides the shell's layout.
  def body_css_classes
    base_classes = "min-h-screen"
    center_classes = "flex items-center justify-center"

    user_signed_in? && !show_auth_layout? ? base_classes : "#{base_classes} #{center_classes}"
  end

  def show_auth_layout?
    devise_controller? && !account_edit_page?
  end

  def show_authenticated_layout?
    user_signed_in?
  end

  private

  def account_edit_page?
    controller_name == "registrations" && action_name == "edit"
  end
end
