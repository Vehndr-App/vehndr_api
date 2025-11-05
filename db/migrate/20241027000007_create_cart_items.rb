class CreateCartItems < ActiveRecord::Migration[8.0]
  def change
    create_table :cart_items, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :cart, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :string
      t.references :vendor, null: false, foreign_key: true, type: :string
      t.integer :quantity, default: 1
      t.jsonb :selected_options, default: {}

      t.timestamps
    end

    add_index :cart_items, :selected_options, using: 'gin'
  end
end


