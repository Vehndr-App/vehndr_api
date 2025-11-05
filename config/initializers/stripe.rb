require 'stripe'

Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key) || ENV['STRIPE_SECRET_KEY']

# For development, you can use test keys
if Rails.env.development? && Stripe.api_key.blank?
  Stripe.api_key = 'sk_test_your_test_key_here'
  Rails.logger.warn "Using default Stripe test key. Please set your own key in credentials or ENV."
end


