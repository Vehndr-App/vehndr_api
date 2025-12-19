class AllowCustomOrderItems < ActiveRecord::Migration[8.0]
  def change
    # Allow null product_id for custom items (from keypad)
    change_column_null :order_items, :product_id, true
    
    # Add is_custom flag
    add_column :order_items, :is_custom, :boolean, default: false
    
    # Remove the foreign key constraint so custom items don't need a product
    remove_foreign_key :order_items, :products
    
    # Re-add the foreign key but only for non-null product_ids
    # This is handled at the application level now
  end
end

