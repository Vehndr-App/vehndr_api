class OrderItem < ApplicationRecord
  # Relationships
  belongs_to :order
  belongs_to :product, optional: true  # Optional for custom items

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_name, presence: true

  # Callbacks
  after_create :book_time_slot_if_service

  # Scopes
  scope :custom_items, -> { where(is_custom: true) }
  scope :product_items, -> { where(is_custom: [false, nil]) }

  # Instance methods
  def subtotal_cents
    price_cents * quantity
  end

  def subtotal_in_dollars
    subtotal_cents / 100.0
  end

  def custom?
    is_custom == true || product_id.nil?
  end

  private

  def book_time_slot_if_service
    return if custom?
    return unless product&.is_service?
    return unless selected_options&.dig('timeSlot').present?

    time_slot = selected_options['timeSlot']
    product.book_time_slot(time_slot)
  end
end


