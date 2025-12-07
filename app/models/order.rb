class Order < ApplicationRecord
  # Constants
  STATUSES = %w[pending confirmed completed cancelled].freeze
  PAYMENT_STATUSES = %w[pending succeeded failed refunded].freeze
  REFUND_STATUSES = %w[none pending_refund partial_refund full_refund].freeze

  # Relationships
  belongs_to :user, optional: true
  belongs_to :vendor
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  # Validations
  validates :total_cents, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }, allow_nil: true
  validates :refund_status, inclusion: { in: REFUND_STATUSES }, allow_nil: true
  validates :guest_email, presence: true, if: -> { user_id.nil? }
  validate :must_have_user_or_guest

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

  # Guest order helpers
  def guest_order?
    user_id.nil?
  end

  def customer_email
    user&.email || guest_email
  end

  def customer_name
    user&.name || guest_name
  end

  # Refund helpers
  def refundable?
    payment_status == 'succeeded' &&
    stripe_charge_id.present? &&
    (refund_status.nil? || refund_status == 'none')
  end

  def refunded?
    refund_status == 'full_refund' || refund_status == 'partial_refund'
  end

  def fully_refunded?
    refund_status == 'full_refund'
  end

  def partially_refunded?
    refund_status == 'partial_refund'
  end

  def refund_amount_in_dollars
    return 0 if refund_amount_cents.nil? || refund_amount_cents.zero?
    refund_amount_cents / 100.0
  end

  def mark_refund_pending!
    update!(refund_status: 'pending_refund')
  end

  def mark_refunded!(refund_id, amount_cents)
    refund_type = amount_cents >= total_cents ? 'full_refund' : 'partial_refund'
    update!(
      refund_status: refund_type,
      refund_amount_cents: amount_cents,
      stripe_refund_id: refund_id,
      refunded_at: Time.current,
      payment_status: refund_type == 'full_refund' ? 'refunded' : payment_status
    )
  end

  private

  def must_have_user_or_guest
    if user_id.nil? && guest_email.blank?
      errors.add(:base, "Order must have either a user or guest email")
    end
  end
end


