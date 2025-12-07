class OrderItem < ApplicationRecord
  # Relationships
  belongs_to :order
  belongs_to :product

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  after_create :book_time_slot_if_service

  # Instance methods
  def subtotal_cents
    price_cents * quantity
  end

  def subtotal_in_dollars
    subtotal_cents / 100.0
  end

  private

  def book_time_slot_if_service
    return unless product.is_service?
    return unless selected_options&.dig('timeSlot').present?

    time_slot = selected_options['timeSlot']
    product.book_time_slot(time_slot)
  end
end


