class Order < ApplicationRecord
  # Constants
  STATUSES = %w[pending confirmed completed cancelled].freeze

  # Relationships
  belongs_to :user
  belongs_to :vendor
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  # Validations
  validates :total_cents, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }

  # Instance methods
  def total_in_dollars
    total_cents / 100.0
  end

  def confirm!
    update!(status: 'confirmed')
  end

  def complete!
    update!(status: 'completed')
  end

  def cancel!
    update!(status: 'cancelled')
  end

  def create_from_cart_items!(cart_items)
    transaction do
      cart_items.each do |item|
        order_items.create!(
          product: item.product,
          quantity: item.quantity,
          price_cents: item.product.price,
          selected_options: item.selected_options
        )
      end
      
      # Update total
      self.total_cents = order_items.sum { |item| item.price_cents * item.quantity }
      save!
    end
  end
end


