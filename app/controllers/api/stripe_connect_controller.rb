module Api
  class StripeConnectController < BaseController
    before_action :authenticate_request
    before_action :set_vendor
    before_action :authorize_vendor_owner

    # POST /api/vendors/:vendor_id/stripe/account_link
    def create_account_link
      refresh_url = params[:refresh_url] || "#{frontend_url}/dashboard"
      return_url = params[:return_url] || "#{frontend_url}/dashboard"

      result = StripeConnectService.create_account_link(@vendor, refresh_url, return_url)

      render json: {
        url: result[:url],
        expiresAt: result[:expires_at].iso8601
      }, status: :ok
    rescue Stripe::StripeError => e
      render_error("Failed to create Stripe account link: #{e.message}", :unprocessable_entity)
    end

    # GET /api/vendors/:vendor_id/stripe/account
    def show_account
      if @vendor.stripe_account_id.blank?
        return render json: {
          connected: false,
          needsOnboarding: true,
          chargesEnabled: false,
          payoutsEnabled: false
        }, status: :ok
      end

      render json: {
        connected: true,
        needsOnboarding: @vendor.needs_stripe_onboarding?,
        chargesEnabled: @vendor.stripe_charges_enabled,
        payoutsEnabled: @vendor.stripe_payouts_enabled,
        detailsSubmitted: @vendor.stripe_details_submitted,
        onboardingCompleted: @vendor.stripe_onboarding_completed,
        connectedAt: @vendor.stripe_connected_at,
        accountId: @vendor.stripe_account_id
      }, status: :ok
    end

    # POST /api/vendors/:vendor_id/stripe/refresh
    def refresh_account
      if @vendor.stripe_account_id.blank?
        return render_error('No Stripe account connected', :bad_request)
      end

      success = StripeConnectService.refresh_account_status(@vendor)

      if success
        @vendor.reload
        render json: {
          success: true,
          chargesEnabled: @vendor.stripe_charges_enabled,
          payoutsEnabled: @vendor.stripe_payouts_enabled,
          detailsSubmitted: @vendor.stripe_details_submitted,
          onboardingCompleted: @vendor.stripe_onboarding_completed
        }, status: :ok
      else
        render_error('Failed to refresh account status', :unprocessable_entity)
      end
    end

    private

    def set_vendor
      @vendor = Vendor.find(params[:id])
    end

    def authorize_vendor_owner
      unless current_user.role == 'vendor' && current_user.vendor_profile&.id == @vendor.id
        render_error('Not authorized to manage this vendor account', :forbidden)
      end
    end

    def frontend_url
      ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    end
  end
end
