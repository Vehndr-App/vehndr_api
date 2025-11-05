class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :string
      t.integer :quantity, null: false
      t.integer :price_cents, null: false
      t.jsonb :selected_options, default: {}

      t.timestamps
    end
  end
end


