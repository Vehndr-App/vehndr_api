class StripeConnectService
  class << self
    def create_account(vendor)
      account = Stripe::Account.create({
        type: 'express',
        country: 'US',
        email: vendor.user&.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true }
        },
        business_type: 'individual',
        metadata: {
          vendor_id: vendor.id,
          vendor_name: vendor.name
        }
      })

      vendor.update!(
        stripe_account_id: account.id,
        stripe_connected_at: Time.current
      )

      account
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe Connect account creation failed: #{e.message}"
      raise
    end

    def create_account_link(vendor, refresh_url, return_url)
      unless vendor.stripe_account_id
        account = create_account(vendor)
        vendor.reload
      end

      account_link = Stripe::AccountLink.create({
        account: vendor.stripe_account_id,
        refresh_url: refresh_url,
        return_url: return_url,
        type: 'account_onboarding'
      })

      {
        url: account_link.url,
        expires_at: Time.at(account_link.expires_at)
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe AccountLink creation failed: #{e.message}"
      raise
    end

    def retrieve_account(stripe_account_id)
      Stripe::Account.retrieve(stripe_account_id)
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe Account retrieval failed: #{e.message}"
      raise
    end

    def update_vendor_from_account(vendor, account = nil)
      account ||= retrieve_account(vendor.stripe_account_id)

      vendor.update!(
        stripe_onboarding_completed: account.details_submitted,
        stripe_charges_enabled: account.charges_enabled,
        stripe_payouts_enabled: account.payouts_enabled,
        stripe_details_submitted: account.details_submitted
      )

      vendor
    end

    def calculate_application_fee(amount_cents, fee_percent = nil)
      fee_percent ||= ENV.fetch('STRIPE_APPLICATION_FEE_PERCENT', '10.0').to_f
      fee_cents = (amount_cents * (fee_percent / 100.0)).round

      # Ensure fee doesn't exceed order total
      [fee_cents, amount_cents].min
    end

    def refresh_account_status(vendor)
      return false unless vendor.stripe_account_id

      account = retrieve_account(vendor.stripe_account_id)
      update_vendor_from_account(vendor, account)
      true
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to refresh account status: #{e.message}"
      false
    end
  end
end
