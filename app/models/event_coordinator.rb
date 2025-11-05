class EventCoordinator < ApplicationRecord
  self.primary_key = :id
  before_create :generate_coordinator_id

  # Validations
  validates :name, presence: true

  private

  def generate_coordinator_id
    self.id = "coord_#{Nanoid.generate(size: 10)}" if id.blank?
  end
end


