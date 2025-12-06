#!/usr/bin/env ruby
# Script to check and fix vendor Stripe status
# Usage: rails runner fix_vendor_stripe.rb

vendor_id = 'vendor_artisan_1'
vendor = Vendor.find(vendor_id)

puts "Vendor: #{vendor.name}"
puts "Stripe Account ID: #{vendor.stripe_account_id}"
puts "Stripe Onboarding Completed: #{vendor.stripe_onboarding_completed}"
puts "Stripe Charges Enabled: #{vendor.stripe_charges_enabled}"
puts "Stripe Payouts Enabled: #{vendor.stripe_payouts_enabled}"
puts "Can Process Payments: #{vendor.can_process_payments?}"

if vendor.stripe_account_id.present? && !vendor.stripe_charges_enabled
  puts "\n⚠️  Vendor has Stripe account but charges are not enabled."
  puts "Checking Stripe account status..."

  begin
    account = Stripe::Account.retrieve(vendor.stripe_account_id)

    puts "\nStripe Account Status:"
    puts "- Charges Enabled: #{account.charges_enabled}"
    puts "- Payouts Enabled: #{account.payouts_enabled}"
    puts "- Details Submitted: #{account.details_submitted}"
    puts "- Requirements: #{account.requirements.to_h}"

    # Update vendor with actual Stripe status
    vendor.update!(
      stripe_charges_enabled: account.charges_enabled,
      stripe_payouts_enabled: account.payouts_enabled,
      stripe_onboarding_completed: account.details_submitted
    )

    puts "\n✅ Updated vendor with Stripe account status"
    puts "Can Process Payments Now: #{vendor.reload.can_process_payments?}"

  rescue Stripe::StripeError => e
    puts "\n❌ Error fetching Stripe account: #{e.message}"
  end
else
  puts "\n✅ Vendor is properly configured"
end
