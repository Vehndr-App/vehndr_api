class ProductOption < ApplicationRecord
  # Relationships
  belongs_to :product

  # Validations
  validates :option_id, presence: true, uniqueness: { scope: :product_id }
  validates :name, presence: true
  validates :option_type, inclusion: { in: %w[select radio checkbox] }
  validates :values, presence: true

  # Default values
  attribute :option_type, :string, default: 'select'
end


