class Product < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  self.primary_key = :id
  before_create :generate_product_id

  # Active Storage attachments
  has_many_attached :images

  # Relationships
  belongs_to :vendor
  has_many :product_options, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :nullify
  has_many :bookings, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration, numericality: { greater_than: 0 }, allow_nil: true, if: :is_service?

  # Scopes
  scope :products_only, -> { where(is_service: false) }
  scope :services_only, -> { where(is_service: true) }

  # Nested attributes
  accepts_nested_attributes_for :product_options, allow_destroy: true

  def price_in_dollars
    price / 100.0 if price
  end

  # Get the primary image (first image)
  def primary_image_url
    if images.attached? && images.first.present?
      begin
        # Use direct S3 URL for production, url_for for development
        Rails.env.production? ? images.first.url : Rails.application.routes.url_helpers.url_for(images.first)
      rescue ArgumentError => e
        Rails.logger.error "Failed to generate image URL: #{e.message}"
        nil
      end
    else
      nil
    end
  end

  # Get all image URLs
  def image_urls
    return [] unless images.attached?

    images.map do |img|
      begin
        # Use direct S3 URL for production, url_for for development
        Rails.env.production? ? img.url : Rails.application.routes.url_helpers.url_for(img)
      rescue ArgumentError => e
        Rails.logger.error "Failed to generate image URL: #{e.message}"
        nil
      end
    end.compact
  end

  private

  def generate_product_id
    prefix = is_service? ? "service" : "prod"
    self.id = "#{prefix}_#{Nanoid.generate(size: 10)}" if id.blank?
  end
end


