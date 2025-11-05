class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products, id: :string do |t|
      t.references :vendor, null: false, foreign_key: true, type: :string
      t.string :name, null: false
      t.text :description
      t.integer :price, null: false # in cents
      t.string :image
      t.boolean :is_service, default: false
      t.integer :duration # in minutes, for services
      t.string :available_time_slots, array: true, default: []

      t.timestamps
    end

    add_index :products, :name
    add_index :products, :is_service
  end
end


