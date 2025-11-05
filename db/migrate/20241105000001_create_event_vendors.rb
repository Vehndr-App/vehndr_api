class CreateEventVendors < ActiveRecord::Migration[8.0]
  def change
    create_table :event_vendors do |t|
      t.references :event, null: false, foreign_key: true, index: true
      t.references :vendor, null: false, type: :string, foreign_key: true, index: true
      t.timestamps
    end

    add_index :event_vendors, [:event_id, :vendor_id], unique: true
  end
end


