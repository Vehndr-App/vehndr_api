class ApplicationController < ActionController::API
  # Skip CSRF for API-only application
  protect_from_forgery with: :null_session if respond_to?(:protect_from_forgery)
end
