class ChangeImageColumnTypeInEvents < ActiveRecord::Migration[8.0]
  def up
    change_column :events, :image, :text
  end

  def down
    change_column :events, :image, :string
  end
end
