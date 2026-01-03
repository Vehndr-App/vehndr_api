class CreateVendorAvailabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :vendor_availabilities do |t|
      t.string :vendor_id, null: false
      t.integer :day_of_week, null: false # 0 = Sunday, 1 = Monday, etc.
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.integer :slot_duration, default: 30, null: false # duration in minutes
      t.integer :employee_count, default: 1, null: false # number of concurrent bookings allowed

      t.timestamps
    end

    add_foreign_key :vendor_availabilities, :vendors, column: :vendor_id
    add_index :vendor_availabilities, :vendor_id
    add_index :vendor_availabilities, [:vendor_id, :day_of_week]
  end
end
