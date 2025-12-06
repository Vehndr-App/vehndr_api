#!/usr/bin/env ruby
# Script to diagnose checkout 422 error
# Usage: rails runner diagnose_checkout_issue.rb

cart_token = 'cfad9d50-91d6-4194-9c66-eb2ada703b6c'
vendor_id = 'vendor_artisan_1'

puts "=== Diagnosing Checkout Issue ==="
puts "Cart Token: #{cart_token}"
puts "Vendor ID: #{vendor_id}"
puts

# Find the cart
cart = Cart.find_by(session_id: cart_token)
unless cart
  puts "❌ Cart not found with session_id: #{cart_token}"
  exit 1
end

puts "✓ Cart found: #{cart.id}"
puts "  Items count: #{cart.cart_items.count}"
puts

# Get cart items with vendor info
cart_items = cart.cart_items.includes(:product, :vendor)
puts "=== Cart Items ==="
cart_items.each do |item|
  puts "Item: #{item.id}"
  puts "  Product: #{item.product&.name || 'MISSING PRODUCT'} (#{item.product_id})"
  puts "  Vendor: #{item.vendor&.name || 'MISSING VENDOR'} (#{item.vendor_id})"
  puts "  Quantity: #{item.quantity}"
  puts "  Subtotal: $#{item.subtotal / 100.0}"
  puts "  Selected Options: #{item.selected_options}"
  puts
end

# Group by vendor
vendor_groups = cart_items.group_by(&:vendor)
puts "=== Vendor Groups ==="
vendor_groups.each do |vendor, items|
  if vendor
    puts "Vendor: #{vendor.name} (#{vendor.id})"
    puts "  Can process payments: #{vendor.can_process_payments?}"
    puts "  Items count: #{items.count}"
  else
    puts "⚠️  Vendor is NULL for #{items.count} item(s)"
    items.each do |item|
      puts "    Item vendor_id: #{item.vendor_id}"
    end
  end
  puts
end

# Check specific vendor
vendor = Vendor.find_by(id: vendor_id)
unless vendor
  puts "❌ Vendor not found: #{vendor_id}"
  exit 1
end

puts "=== Target Vendor ==="
puts "Vendor: #{vendor.name}"
puts "Can process payments: #{vendor.can_process_payments?}"
puts "Stripe Account ID: #{vendor.stripe_account_id}"
puts "Charges Enabled: #{vendor.stripe_charges_enabled}"
puts

# Check if vendor has items in cart
items_for_vendor = vendor_groups[vendor]
if items_for_vendor.nil?
  puts "❌ No items in cart for vendor: #{vendor.name}"
  puts "   This would cause a 400 error: 'No items for this vendor in cart'"
  puts
  puts "=== Cart items are for these vendors instead: ==="
  vendor_groups.each do |v, _|
    puts "  - #{v&.name} (#{v&.id})" if v
  end
  exit 1
elsif items_for_vendor.empty?
  puts "❌ Empty items array for vendor: #{vendor.name}"
  exit 1
else
  puts "✓ Found #{items_for_vendor.count} item(s) for vendor"
  puts
end

# Simulate creating Stripe session
puts "=== Testing Stripe Session Creation ==="
total_cents = items_for_vendor.sum(&:subtotal)
puts "Total: $#{total_cents / 100.0}"

begin
  # Check if vendor has all required Stripe fields
  unless vendor.stripe_account_id.present?
    puts "❌ Missing stripe_account_id"
    exit 1
  end

  puts "✓ Vendor has Stripe account ID"

  # Try to retrieve the Stripe account
  account = Stripe::Account.retrieve(vendor.stripe_account_id)
  puts "✓ Stripe account is accessible"
  puts "  Charges enabled: #{account.charges_enabled}"
  puts "  Payouts enabled: #{account.payouts_enabled}"

  unless account.charges_enabled
    puts "❌ Stripe account cannot accept charges"
    exit 1
  end

  puts
  puts "✅ All checks passed! The checkout should work."
  puts
  puts "=== Recommendation ==="
  puts "If checkout is still failing, it's likely a Stripe API error."
  puts "Check STRIPE_SECRET_KEY environment variable and Stripe Connect settings."

rescue Stripe::StripeError => e
  puts "❌ Stripe Error: #{e.message}"
  puts "   Error Type: #{e.class.name}"
  puts "   This would cause a 422 error in checkout"
rescue => e
  puts "❌ Unexpected Error: #{e.message}"
  puts "   #{e.class.name}"
  puts "   Backtrace:"
  puts e.backtrace.first(5).map { |line| "     #{line}" }.join("\n")
end
