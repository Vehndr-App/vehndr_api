class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.string :vendor_id, null: false
      t.string :product_id, null: false
      t.uuid :order_item_id, null: true
      t.bigint :employee_id, null: true
      t.date :booking_date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :status, default: 'pending', null: false
      t.string :customer_name
      t.string :customer_email
      t.string :customer_phone

      t.timestamps
    end

    add_foreign_key :bookings, :vendors, column: :vendor_id
    add_foreign_key :bookings, :products, column: :product_id
    add_foreign_key :bookings, :order_items, column: :order_item_id
    add_foreign_key :bookings, :employees
    add_index :bookings, :vendor_id
    add_index :bookings, :product_id
    add_index :bookings, :order_item_id
    add_index :bookings, [:vendor_id, :booking_date]
    add_index :bookings, [:vendor_id, :booking_date, :start_time]
    add_index :bookings, :status
  end
end
