class Cart < ApplicationRecord
  # Relationships
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  has_many :vendors, through: :cart_items

  # Validations
  validate :has_user_or_session

  # Instance methods
  def items_grouped_by_vendor
    cart_items.includes(:product, :vendor)
              .group_by(&:vendor_id)
  end

  def total_amount
    cart_items.includes(:product).sum { |item| item.product.price * item.quantity }
  end

  def total_amount_in_dollars
    total_amount / 100.0
  end

  def clear_vendor_items(vendor_id)
    cart_items.where(vendor_id: vendor_id).destroy_all
  end

  def merge_guest_cart!(guest_cart)
    return if guest_cart == self

    guest_cart.cart_items.each do |item|
      existing = cart_items.find_by(
        product_id: item.product_id,
        selected_options: item.selected_options
      )

      if existing
        existing.update!(quantity: existing.quantity + item.quantity)
      else
        item.update!(cart: self)
      end
    end

    guest_cart.reload.destroy! if guest_cart.cart_items.empty?
  end

  private

  def has_user_or_session
    if user_id.blank? && session_id.blank?
      errors.add(:base, "Cart must belong to a user or have a session ID")
    end
  end
end


