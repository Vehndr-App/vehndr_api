class AddPaymentTrackingToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :stripe_charge_id, :string
    add_column :orders, :application_fee_cents, :integer, default: 0
    add_column :orders, :platform_fee_percent, :decimal, precision: 5, scale: 2
    add_column :orders, :payment_status, :string, default: 'pending'

    add_index :orders, :stripe_charge_id
    add_index :orders, :payment_status
  end
end
