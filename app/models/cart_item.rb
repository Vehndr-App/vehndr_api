class CartItem < ApplicationRecord
  # Relationships
  belongs_to :cart
  belongs_to :product
  belongs_to :vendor

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validate :validate_selected_options
  validate :validate_time_slot_availability, if: -> { product&.is_service? }

  # Callbacks
  before_validation :set_vendor_from_product

  # Instance methods
  def subtotal
    product.price * quantity
  end

  def subtotal_in_dollars
    subtotal / 100.0
  end

  private

  def set_vendor_from_product
    self.vendor = product.vendor if product
  end

  def validate_selected_options
    return unless product

    product.product_options.each do |option|
      unless selected_options[option.option_id].present?
        errors.add(:selected_options, "#{option.name} is required")
      end

      if selected_options[option.option_id].present? && 
         !option.values.include?(selected_options[option.option_id])
        errors.add(:selected_options, "Invalid value for #{option.name}")
      end
    end
  end

  def validate_time_slot_availability
    return unless selected_options['timeSlot'].present?

    time_slot = selected_options['timeSlot']

    # Check if time slot exists and is available (not booked)
    unless product.time_slot_available?(time_slot)
      errors.add(:selected_options, "Time slot #{time_slot} is not available")
      return
    end

    # Check if time slot is in another cart (temporary reservation)
    existing_bookings = CartItem.joins(:product, :cart)
                                .where(products: { id: product.id })
                                .where.not(cart_id: cart_id)
                                .where("selected_options->>'timeSlot' = ?", time_slot)

    if existing_bookings.exists?
      errors.add(:selected_options, "Time slot #{time_slot} is already in another cart")
    end
  end
end


