class CreateVendors < ActiveRecord::Migration[8.0]
  def change
    create_table :vendors, id: :string do |t|
      t.string :name, null: false
      t.text :description
      t.string :hero_image
      t.string :location
      t.decimal :rating, precision: 2, scale: 1, default: 0.0
      t.string :categories, array: true, default: []

      t.timestamps
    end

    add_index :vendors, :name
    add_index :vendors, :categories, using: 'gin'
  end
end


