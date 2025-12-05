class AddStripeConnectToVendors < ActiveRecord::Migration[8.0]
  def change
    add_column :vendors, :stripe_account_id, :string
    add_column :vendors, :stripe_onboarding_completed, :boolean, default: false
    add_column :vendors, :stripe_charges_enabled, :boolean, default: false
    add_column :vendors, :stripe_payouts_enabled, :boolean, default: false
    add_column :vendors, :stripe_details_submitted, :boolean, default: false
    add_column :vendors, :stripe_connected_at, :datetime

    add_index :vendors, :stripe_account_id
    add_index :vendors, :stripe_charges_enabled
  end
end
