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

  def form_input_classes
    "w-full px-3 py-2 bg-surface border border-line rounded-sleeve text-fg placeholder:text-fg-subtle"
  end

  def primary_button_classes
    "w-full bg-accent text-accent-fg py-2 px-4 rounded-sleeve font-medium hover:bg-accent-hover transition duration-200"
  end

  def form_label_classes
    "block text-sm font-medium text-fg-muted mb-1"
  end

  def help_text_classes
    "text-xs text-fg-subtle mt-1"
  end

  def success_button_classes
    "w-full bg-ok text-surface py-2 px-4 rounded-sleeve font-medium hover:bg-ok-hover transition duration-200"
  end

  private

  def account_edit_page?
    controller_name == "registrations" && action_name == "edit"
  end
end
