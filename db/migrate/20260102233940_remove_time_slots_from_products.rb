class RemoveTimeSlotsFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :available_time_slots, :string, array: true, default: []
    remove_column :products, :booked_time_slots, :string, array: true, default: []
  end
end
