class AddGuestSupportToOrders < ActiveRecord::Migration[8.0]
  def change
    # Make user_id nullable to allow guest orders
    change_column_null :orders, :user_id, true

    # Add guest customer fields
    add_column :orders, :guest_email, :string
    add_column :orders, :guest_name, :string
    add_column :orders, :guest_phone, :string

    # Add check constraint: must have either user_id OR guest_email
    add_check_constraint :orders,
      "(user_id IS NOT NULL) OR (guest_email IS NOT NULL)",
      name: "orders_must_have_user_or_guest"
  end
end
