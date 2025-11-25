class Vendor < ApplicationRecord
  self.primary_key = :id
  before_create :generate_vendor_id

  # Relationships
  belongs_to :user, optional: true
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :cart_items, dependent: :destroy
  has_many :event_vendors, dependent: :destroy
  has_many :events, through: :event_vendors

  # Validations
  validates :name, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true

  # Scopes
  scope :by_category, ->(category) { where("? = ANY(categories)", category) }

  private

  def generate_vendor_id
    self.id = "vendor_#{Nanoid.generate(size: 10)}" if id.blank?
  end
end


