class RemoveHeroImageFromVendors < ActiveRecord::Migration[8.0]
  def change
    remove_column :vendors, :hero_image, :string
  end
end
