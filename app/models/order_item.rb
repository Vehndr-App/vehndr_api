class OrderItem < ApplicationRecord
  # Relationships
  belongs_to :order
  belongs_to :product, optional: true  # Optional for custom items
  has_one :booking, dependent: :destroy

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
    return unless selected_options&.dig('timeSlot').present? && selected_options&.dig('date').present?

    # Create a booking instead of marking time slots on products
    begin
      date = Date.parse(selected_options['date'])
      time_slot = selected_options['timeSlot']
      start_time = Time.parse(time_slot)

      Booking.create!(
        vendor_id: product.vendor_id,
        product_id: product.id,
        order_item_id: id,
        booking_date: date,
        start_time: start_time,
        customer_name: order.user&.name || selected_options['customerName'],
        customer_email: order.user&.email || selected_options['customerEmail'],
        customer_phone: selected_options['customerPhone'],
        status: 'confirmed'
      )
    rescue => e
      Rails.logger.error "Failed to create booking for order_item #{id}: #{e.message}"
      # Don't fail the order creation if booking fails
    end
  end
end


