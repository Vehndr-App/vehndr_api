module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token if defined?(verify_authenticity_token)
    before_action :set_default_format

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    
    protected

    def current_cart
      @current_cart ||= find_or_create_cart
    end

    private

    def set_default_format
      request.format = :json
    end

    def find_or_create_cart
      if defined?(@current_user) && @current_user
        @current_user.current_cart
      else
        session_id = session[:cart_session_id] ||= SecureRandom.uuid
        Cart.find_or_create_by(session_id: session_id)
      end
    end

    def current_user
      return @current_user if defined?(@current_user)
      
      header = request.headers['Authorization']
      header = header.split(' ').last if header
      
      if header
        begin
          decoded = JsonWebToken.decode(header)
          @current_user = User.find(decoded[:user_id]) if decoded
        rescue
          @current_user = nil
        end
      end
      
      @current_user
    end

    def not_found(exception)
      render json: { error: exception.message }, status: :not_found
    end

    def unprocessable_entity(exception)
      render json: { 
        error: 'Validation failed',
        errors: exception.record.errors.full_messages 
      }, status: :unprocessable_entity
    end

    def render_error(message, status = :bad_request)
      render json: { error: message }, status: status
    end
  end
end
