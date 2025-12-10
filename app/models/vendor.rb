class Vendor < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  self.primary_key = :id
  before_create :generate_vendor_id

  # Active Storage
  has_one_attached :hero_image
  has_many_attached :gallery_images

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
    process_image_url(hero_image)
  end

  def gallery_image_urls
    return [] unless gallery_images.attached?
    gallery_images.map { |image| process_image_url(image) }
  end


  def process_image_url(image)
    # Check if image needs conversion (HEIC/HEIF format)
    content_type = image.content_type.to_s.downcase
    needs_conversion = content_type.include?('heic') || content_type.include?('heif')
    
    if needs_conversion && defined?(ImageProcessing)
      # Use variant to convert HEIC/HEIF to web-compatible JPEG
      begin
        variant = image.variant(format: :jpeg, saver: { quality: 85 })
        return Rails.application.routes.url_helpers.url_for(variant)
      rescue => e
        Rails.logger.warn "Image variant conversion failed: #{e.message}"
      end
    end
    
    # Return original URL (or if conversion failed)
    if Rails.env.production?
      image.url
    else
      Rails.application.routes.url_helpers.url_for(image)
    end
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


