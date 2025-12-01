class AddCoordinatorIdToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :coordinator_id, :string
    add_index :events, :coordinator_id
    add_foreign_key :events, :event_coordinators, column: :coordinator_id, primary_key: :id
  end
end
