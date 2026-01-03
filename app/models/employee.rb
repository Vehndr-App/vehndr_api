class Employee < ApplicationRecord
  belongs_to :vendor
  has_many :bookings, dependent: :nullify

  validates :name, presence: true
  validates :email, uniqueness: { scope: :vendor_id, allow_nil: true }

  scope :active, -> { where(active: true) }
end
