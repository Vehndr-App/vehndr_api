class CreateProductOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :product_options, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :product, null: false, foreign_key: true, type: :string
      t.string :option_id, null: false
      t.string :name, null: false
      t.string :option_type, default: 'select'
      t.string :values, array: true, default: []

      t.timestamps
    end

    add_index :product_options, [:product_id, :option_id], unique: true
  end
end


