class CreateCarts < ActiveRecord::Migration[8.0]
  def change
    create_table :carts, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.string :session_id

      t.timestamps
    end

    add_index :carts, :session_id
  end
end


