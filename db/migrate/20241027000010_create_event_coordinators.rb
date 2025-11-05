class CreateEventCoordinators < ActiveRecord::Migration[8.0]
  def change
    create_table :event_coordinators, id: :string do |t|
      t.string :name, null: false
      t.string :organization
      t.text :bio
      t.string :avatar

      t.timestamps
    end

    add_index :event_coordinators, :name
  end
end


