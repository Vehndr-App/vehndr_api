class EventCoordinator < ApplicationRecord
  self.primary_key = :id
  before_create :generate_coordinator_id

  belongs_to :user, optional: true
  has_many :events, foreign_key: :coordinator_id, primary_key: :id, dependent: :destroy

  # Validations
  validates :name, presence: true

  private

  def generate_coordinator_id
    self.id = "coord_#{Nanoid.generate(size: 10)}" if id.blank?
  end
end


