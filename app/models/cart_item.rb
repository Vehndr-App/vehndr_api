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
    return unless selected_options['timeSlot'].present? && selected_options['date'].present?

    time_slot = selected_options['timeSlot']
    date = begin
      Date.parse(selected_options['date'])
    rescue ArgumentError
      errors.add(:selected_options, "Invalid date format")
      return
    end

    # Check vendor availability for this date and time
    unless vendor.slot_available?(date, time_slot)
      errors.add(:selected_options, "Time slot #{time_slot} is not available on #{date}")
      return
    end

    # Check if time slot is in another cart for the same date (temporary reservation)
    existing_bookings = CartItem.joins(:cart)
                                .where(vendor_id: vendor_id)
                                .where.not(cart_id: cart_id)
                                .where("selected_options->>'timeSlot' = ?", time_slot)
                                .where("selected_options->>'date' = ?", selected_options['date'])

    if existing_bookings.exists?
      # Check if we're exceeding vendor capacity
      availability = vendor.vendor_availabilities.find_by(day_of_week: date.wday)
      if availability
        capacity = availability.available_capacity_at(date, time_slot)
        # Account for cart reservations
        if capacity - existing_bookings.count <= 0
          errors.add(:selected_options, "Time slot #{time_slot} is fully booked on #{date}")
        end
      end
    end
  end
end


