module Api
  class PasswordController < BaseController
    # skip_before_action :authenticate_request, only: [:forgot, :reset, :validate_token]

    # POST /api/password/forgot
    def forgot
      email = params[:email]&.downcase&.strip
      
      unless email.present?
        render json: { error: "Email is required" }, status: :unprocessable_entity
        return
      end

      user = User.find_by(email: email)
      
      # Always return success to prevent email enumeration
      if user
        token = generate_reset_token(user)
        # In production, send email here
        # PasswordMailer.reset_instructions(user, token).deliver_later
        
        # For development, log the token
        Rails.logger.info "Password reset token for #{email}: #{token}"
        Rails.logger.info "Reset URL: #{ENV['FRONTEND_URL']}/reset-password?token=#{token}"
      end
      
      render json: { 
        message: "If an account exists with this email, password reset instructions have been sent." 
      }, status: :ok
    end

    # GET /api/password/validate_token
    def validate_token
      token = params[:token]
      
      unless token.present?
        render json: { valid: false, error: "Token is required" }, status: :unprocessable_entity
        return
      end

      reset_record = PasswordResetToken.find_by(token: token)
      
      if reset_record && !reset_record.expired? && !reset_record.used?
        render json: { valid: true }, status: :ok
      else
        render json: { valid: false, error: "Invalid or expired token" }, status: :unprocessable_entity
      end
    end

    # POST /api/password/reset
    def reset
      token = params[:token]
      password = params[:password]
      password_confirmation = params[:password_confirmation]

      unless token.present? && password.present?
        render json: { error: "Token and password are required" }, status: :unprocessable_entity
        return
      end

      if password != password_confirmation
        render json: { error: "Passwords do not match" }, status: :unprocessable_entity
        return
      end

      if password.length < 8
        render json: { error: "Password must be at least 8 characters" }, status: :unprocessable_entity
        return
      end

      reset_record = PasswordResetToken.find_by(token: token)
      
      unless reset_record && !reset_record.expired? && !reset_record.used?
        render json: { error: "Invalid or expired token" }, status: :unprocessable_entity
        return
      end

      user = reset_record.user
      
      if user.update(password: password)
        # Mark token as used
        reset_record.update(used_at: Time.current)
        
        # Invalidate all other reset tokens for this user
        user.password_reset_tokens.where(used_at: nil).where.not(id: reset_record.id).update_all(used_at: Time.current)
        
        render json: { message: "Password has been reset successfully" }, status: :ok
      else
        render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    private

    def generate_reset_token(user)
      token = SecureRandom.urlsafe_base64(32)
      
      # Create reset token record
      user.password_reset_tokens.create!(
        token: token,
        expires_at: 2.hours.from_now
      )
      
      token
    end
  end
end

