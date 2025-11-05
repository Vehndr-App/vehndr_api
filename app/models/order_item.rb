class OrderItem < ApplicationRecord
  # Relationships
  belongs_to :order
  belongs_to :product

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Instance methods
  def subtotal_cents
    price_cents * quantity
  end

  def subtotal_in_dollars
    subtotal_cents / 100.0
  end
end


