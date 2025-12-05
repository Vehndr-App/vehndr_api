class Order < ApplicationRecord
  # Constants
  STATUSES = %w[pending confirmed completed cancelled].freeze
  PAYMENT_STATUSES = %w[pending succeeded failed refunded].freeze

  # Relationships
  belongs_to :user
  belongs_to :vendor
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  # Validations
  validates :total_cents, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }, allow_nil: true

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

  # Payment tracking methods
  def application_fee_in_dollars
    return 0 if application_fee_cents.nil? || application_fee_cents.zero?
    application_fee_cents / 100.0
  end

  def vendor_payout_cents
    total_cents - (application_fee_cents || 0)
  end

  def vendor_payout_in_dollars
    vendor_payout_cents / 100.0
  end

  def payment_succeeded?
    payment_status == 'succeeded'
  end

  def payment_failed?
    payment_status == 'failed'
  end

  def payment_pending?
    payment_status == 'pending' || payment_status.nil?
  end

  def mark_payment_succeeded!
    update!(payment_status: 'succeeded')
  end

  def mark_payment_failed!
    update!(payment_status: 'failed', status: 'cancelled')
  end
end


