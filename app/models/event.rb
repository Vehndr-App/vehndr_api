class Event < ApplicationRecord
  has_many :event_vendors, dependent: :destroy
  has_many :vendors, through: :event_vendors

  STATUSES = %w[upcoming active past].freeze

  validates :name, presence: true
  validates :start_date, :end_date, presence: true
  validates :status, inclusion: { in: STATUSES }
end


