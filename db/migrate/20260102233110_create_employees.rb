class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.string :vendor_id, null: false
      t.string :name, null: false
      t.string :email
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_foreign_key :employees, :vendors, column: :vendor_id
    add_index :employees, :vendor_id
    add_index :employees, [:vendor_id, :email], unique: true, where: "email IS NOT NULL"
  end
end
