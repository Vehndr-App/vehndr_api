class Booking < ApplicationRecord
  belongs_to :vendor
  belongs_to :product
  belongs_to :order_item, optional: true
  belongs_to :employee, optional: true

  validates :booking_date, :start_time, :end_time, :status, presence: true
  validates :status, inclusion: { in: %w[pending confirmed completed cancelled] }
  validate :check_capacity_available
  validate :end_time_after_start_time

  before_validation :set_end_time, if: -> { end_time.blank? && start_time.present? && product.present? }
  before_validation :assign_employee, if: -> { employee_id.blank? }

  scope :upcoming, -> { where('booking_date >= ?', Date.today).order(:booking_date, :start_time) }
  scope :past, -> { where('booking_date < ?', Date.today).order(booking_date: :desc, start_time: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  private

  def set_end_time
    if product.is_service && product.duration.present?
      self.end_time = start_time + product.duration.minutes
    end
  end

  def assign_employee
    # Find an available employee for this time slot
    available_employee = vendor.employees.active.find do |emp|
      !emp.bookings.exists?(
        booking_date: booking_date,
        status: ['pending', 'confirmed']
      ) || emp.bookings.where(
        booking_date: booking_date,
        status: ['pending', 'confirmed']
      ).none? { |b| times_overlap?(b.start_time, b.end_time, start_time, end_time) }
    end

    self.employee = available_employee if available_employee
  end

  def check_capacity_available
    return unless booking_date.present? && start_time.present?

    availability = vendor.vendor_availabilities.find_by(day_of_week: booking_date.wday)

    if availability.nil?
      errors.add(:booking_date, "Vendor is not available on this day")
      return
    end

    time_slot = start_time.strftime('%I:%M %p')
    capacity = availability.available_capacity_at(booking_date, time_slot)

    if capacity <= 0
      errors.add(:start_time, "This time slot is fully booked")
    end
  end

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end

  def times_overlap?(start1, end1, start2, end2)
    start1 < end2 && end1 > start2
  end
end
