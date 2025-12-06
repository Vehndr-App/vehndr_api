module Api
  class AuthController < BaseController
    # No authentication needed for auth endpoints

    # POST /api/auth/login
    def login
      user = User.find_by(email: params[:email]&.downcase)

      if user&.authenticate(params[:password])
        # Merge guest cart with user cart if applicable
        if session[:cart_session_id].present?
          guest_cart = Cart.find_by(session_id: session[:cart_session_id])
          user.current_cart.merge_guest_cart!(guest_cart) if guest_cart
        end

        token = JsonWebToken.encode(user_id: user.id)

        render json: {
          token: token,
          user: UserSerializer.new(user)
        }
      else
        render_error('Invalid email or password', :unauthorized)
      end
    end

    # POST /api/auth/register
    def register
      user = User.new(user_params)
      user.role = 'customer' unless params[:role].in?(%w[vendor coordinator])

      if user.save
        # Merge guest cart with new user cart if applicable
        if session[:cart_session_id].present?
          guest_cart = Cart.find_by(session_id: session[:cart_session_id])
          user.current_cart.merge_guest_cart!(guest_cart) if guest_cart
        end

        token = JsonWebToken.encode(user_id: user.id)

        render json: {
          token: token,
          user: UserSerializer.new(user)
        }, status: :created
      else
        render json: {
          error: 'Registration failed',
          errors: user.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    # POST /api/auth/logout
    def logout
      # For JWT, logout is handled client-side by removing the token
      # But we can clear the session
      session[:cart_session_id] = nil
      render json: { message: 'Logged out successfully' }
    end

    # GET /api/auth/current_user
    def current_user_info
      if current_user
        render json: current_user, serializer: UserSerializer
      else
        render json: { user: nil }
      end
    end

    private

    def user_params
      params.permit(:email, :password, :password_confirmation, :name, :role)
    end

    def verify_recaptcha_token
      recaptcha_token = params[:recaptcha_token]
      return false if recaptcha_token.blank?

      secret_key = Recaptcha.configuration.secret_key
      return false if secret_key.blank?

      uri = URI.parse("https://www.google.com/recaptcha/api/siteverify")
      response = Net::HTTP.post_form(uri, {
        secret: secret_key,
        response: recaptcha_token,
        remoteip: request.remote_ip
      })

      result = JSON.parse(response.body)
      result["success"] == true
    rescue => e
      Rails.logger.error "reCAPTCHA verification error: #{e.message}"
      false
    end

    def current_user
      return @current_user if defined?(@current_user)

      header = request.headers['Authorization']
      header = header.split(' ').last if header

      if header
        decoded = JsonWebToken.decode(header)
        @current_user = User.find(decoded[:user_id]) if decoded
      end

      @current_user
    rescue
      @current_user = nil
    end
  end
end
