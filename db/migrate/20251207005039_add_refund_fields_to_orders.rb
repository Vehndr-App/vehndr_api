class AddRefundFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :refund_status, :string
    add_column :orders, :refund_amount_cents, :integer, default: 0
    add_column :orders, :refunded_at, :datetime
    add_column :orders, :stripe_refund_id, :string

    add_index :orders, :refund_status
    add_index :orders, :stripe_refund_id
  end
end
