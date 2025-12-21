class Product < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  self.primary_key = :id
  before_create :generate_product_id
  before_create :set_default_time_slots, if: :is_service?

  # Active Storage attachments
  has_many_attached :images

  # Relationships
  belongs_to :vendor
  has_many :product_options, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :nullify

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

  # Get currently available (unbooked) time slots
  def currently_available_time_slots
    return [] unless is_service? && available_time_slots.present?
    available_time_slots - (booked_time_slots || [])
  end

  # Book a time slot
  def book_time_slot(time_slot)
    return false unless is_service? && available_time_slots.include?(time_slot)
    return false if booked_time_slots.include?(time_slot)

    update(booked_time_slots: (booked_time_slots || []) + [time_slot])
  end

  # Check if a time slot is available
  def time_slot_available?(time_slot)
    return false unless is_service? && available_time_slots.include?(time_slot)
    !booked_time_slots.include?(time_slot)
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

  # Generate default time slots for a service (24 hours, 30-minute intervals)
  def self.default_time_slots
    [
      '12:00 AM', '12:30 AM', '1:00 AM', '1:30 AM', '2:00 AM', '2:30 AM',
      '3:00 AM', '3:30 AM', '4:00 AM', '4:30 AM', '5:00 AM', '5:30 AM',
      '6:00 AM', '6:30 AM', '7:00 AM', '7:30 AM', '8:00 AM', '8:30 AM',
      '9:00 AM', '9:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
      '12:00 PM', '12:30 PM', '1:00 PM', '1:30 PM', '2:00 PM', '2:30 PM',
      '3:00 PM', '3:30 PM', '4:00 PM', '4:30 PM', '5:00 PM', '5:30 PM',
      '6:00 PM', '6:30 PM', '7:00 PM', '7:30 PM', '8:00 PM', '8:30 PM',
      '9:00 PM', '9:30 PM', '10:00 PM', '10:30 PM', '11:00 PM', '11:30 PM'
    ]
  end

  private

  def generate_product_id
    prefix = is_service? ? "service" : "prod"
    self.id = "#{prefix}_#{Nanoid.generate(size: 10)}" if id.blank?
  end

  def set_default_time_slots
    # Only set default time slots if none are provided
    if available_time_slots.blank?
      self.available_time_slots = self.class.default_time_slots
    end
  end
end


