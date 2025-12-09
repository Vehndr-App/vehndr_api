class PasswordResetToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(used_at: nil).where('expires_at > ?', Time.current) }

  def expired?
    expires_at < Time.current
  end

  def used?
    used_at.present?
  end
end

