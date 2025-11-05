class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.text :description
      t.string :location
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.string :image
      t.string :category
      t.integer :attendees, null: false, default: 0
      t.string :status, null: false, default: "upcoming"
      t.timestamps
    end

    add_index :events, :status
    add_index :events, :start_date
  end
end


