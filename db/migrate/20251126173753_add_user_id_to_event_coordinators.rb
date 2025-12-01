class AddUserIdToEventCoordinators < ActiveRecord::Migration[8.0]
  def change
    add_reference :event_coordinators, :user, type: :uuid, null: true, foreign_key: true
  end
end
