class AddInPersonFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :is_in_person, :boolean, default: false
    add_column :orders, :payment_method, :string
    add_column :order_items, :product_name, :string
    
    add_index :orders, :is_in_person
    add_index :orders, :payment_method
  end
end

