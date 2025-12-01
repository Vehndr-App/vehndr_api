class User < ApplicationRecord
  has_secure_password

  # Relationships
  has_one :vendor_profile, class_name: 'Vendor', dependent: :destroy
  has_one :coordinator_profile, class_name: 'EventCoordinator', dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :nullify

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: :password_required?
  validates :role, inclusion: { in: %w[customer vendor coordinator] }

  # Callbacks
  before_save :downcase_email

  # Scopes
  scope :customers, -> { where(role: 'customer') }
  scope :vendors, -> { where(role: 'vendor') }
  scope :coordinators, -> { where(role: 'coordinator') }

  def current_cart(session_id = nil)
    cart = carts.order(created_at: :desc).first
    cart ||= carts.create! if persisted?
    cart
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def password_required?
    new_record? || password.present?
  end
end


