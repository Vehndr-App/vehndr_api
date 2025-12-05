class Vendor < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  self.primary_key = :id
  before_create :generate_vendor_id

  # Active Storage
  has_one_attached :hero_image

  # Relationships
  belongs_to :user, optional: true
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :cart_items, dependent: :destroy
  has_many :event_vendors, dependent: :destroy
  has_many :events, through: :event_vendors

  # Validations
  validates :name, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true

  # Scopes
  scope :by_category, ->(category) { where("? = ANY(categories)", category) }

  # Instance methods
  def hero_image_url
    return nil unless hero_image.attached?
    # Use url_for with host to generate full URL for API responses
    Rails.application.routes.url_helpers.url_for(hero_image)
  end

  # Stripe Connect helpers
  def needs_stripe_onboarding?
    stripe_account_id.blank? || !stripe_onboarding_completed
  end

  def stripe_account_active?
    stripe_account_id.present? && stripe_onboarding_completed
  end

  def can_process_payments?
    stripe_account_id.present? && stripe_charges_enabled
  end

  def stripe_ready_for_checkout?
    can_process_payments?
  end

  private

  def generate_vendor_id
    self.id = "vendor_#{Nanoid.generate(size: 10)}" if id.blank?
  end
end


