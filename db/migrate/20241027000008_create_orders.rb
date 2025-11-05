class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :vendor, null: false, foreign_key: true, type: :string
      t.integer :total_cents, null: false
      t.string :status, default: 'pending'
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id

      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, :stripe_checkout_session_id
  end
end


