module ApplicationHelper
  include Pagy::Frontend

  def body_css_classes
    if devise_controller? && !account_edit_page?
      "bg-gray-100 min-h-screen flex items-center justify-center"
    elsif user_signed_in?
      "bg-gray-100 min-h-screen"
    else
      "bg-gray-100 min-h-screen flex items-center justify-center"
    end
  end

  def show_auth_layout?
    devise_controller? && !account_edit_page?
  end

  def show_authenticated_layout?
    user_signed_in?
  end

  def form_input_classes
    "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
  end

  def primary_button_classes
    "w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition duration-200"
  end

  def form_label_classes
    "block text-sm font-medium text-gray-700 mb-1"
  end

  def help_text_classes
    "text-xs text-gray-500 mt-1"
  end

  def success_button_classes
    "w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition duration-200"
  end

  private

  def account_edit_page?
    controller_name == "registrations" && action_name == "edit"
  end
end
