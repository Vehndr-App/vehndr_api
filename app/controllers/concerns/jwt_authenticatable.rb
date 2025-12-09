module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request, except: [:login, :logout]
  end

  private

  def authenticate_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    begin
      decoded = JsonWebToken.decode(header)
      @current_user = User.find(decoded[:user_id])
    rescue JWT::DecodeError => e
      render json: { error: 'Invalid token' }, status: :unauthorized
      return false
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'User not found' }, status: :unauthorized
      return false
    end
  end

  def current_user
    @current_user
  end

  def logged_in?
    !!current_user
  end

  def authorize_user!(role = nil)
    unless logged_in?
      render json: { error: 'Not authorized' }, status: :unauthorized
      return
    end

    if role && current_user.role != role
      render json: { error: 'Insufficient permissions' }, status: :forbidden
    end
  end
end


