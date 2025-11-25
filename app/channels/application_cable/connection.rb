# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Extract token from query params or headers
      token = request.params[:token] || extract_token_from_headers
      
      if token
        decoded = JsonWebToken.decode(token)
        if decoded && (user = User.find_by(id: decoded[:user_id]))
          user
        else
          reject_unauthorized_connection
        end
      else
        reject_unauthorized_connection
      end
    rescue
      reject_unauthorized_connection
    end

    def extract_token_from_headers
      # ActionCable doesn't have standard HTTP headers, but we can try
      # Usually token is passed via query params for WebSocket connections
      nil
    end
  end
end



