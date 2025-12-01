class RemoveImageFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :image, :string
  end
end
