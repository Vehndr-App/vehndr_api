class Product < ApplicationRecord
  self.primary_key = :id
  before_create :generate_product_id

  # Relationships
  belongs_to :vendor
  has_many :product_options, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration, numericality: { greater_than: 0 }, allow_nil: true, if: :is_service?

  # Scopes
  scope :products_only, -> { where(is_service: false) }
  scope :services_only, -> { where(is_service: true) }

  # Nested attributes
  accepts_nested_attributes_for :product_options, allow_destroy: true

  def price_in_dollars
    price / 100.0 if price
  end

  private

  def generate_product_id
    prefix = is_service? ? "service" : "prod"
    self.id = "#{prefix}_#{Nanoid.generate(size: 10)}" if id.blank?
  end
end


