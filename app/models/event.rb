class Event < ApplicationRecord
  vectorsearch

  after_save :safe_upsert_to_vectorsearch
  
  belongs_to :coordinator, class_name: 'EventCoordinator', foreign_key: :coordinator_id, primary_key: :id, optional: true
  has_many :event_vendors, dependent: :destroy
  has_many :vendors, through: :event_vendors

  STATUSES = %w[draft upcoming active past].freeze

  validates :name, presence: true
  validates :start_date, :end_date, presence: true
  validates :status, inclusion: { in: STATUSES }

  private

  def safe_upsert_to_vectorsearch
    upsert_to_vectorsearch
  rescue StandardError => e
    Rails.logger.warn "Vectorsearch upsert failed for Event #{id}: #{e.message}"
    # Don't raise - allow the event to be saved without vectorsearch
  end
end


