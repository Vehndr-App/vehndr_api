class AddBookedTimeSlotsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :booked_time_slots, :string, array: true, default: []
  end
end
