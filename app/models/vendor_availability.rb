class VendorAvailability < ApplicationRecord
  belongs_to :vendor

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :start_time, :end_time, :slot_duration, :employee_count, presence: true
  validates :slot_duration, numericality: { greater_than: 0 }
  validates :employee_count, numericality: { greater_than: 0 }
  validate :end_time_after_start_time

  # Generate all available time slots for this availability window
  def generate_time_slots
    slots = []
    current_time = start_time

    while current_time < end_time
      slots << current_time.strftime('%I:%M %p')
      current_time += slot_duration.minutes
    end

    slots
  end

  # Check if a specific time slot is available on a given date
  def available_capacity_at(date, time_slot)
    return 0 unless matches_date?(date)

    # Parse the time slot string to a Time object for comparison
    slot_time = Time.parse(time_slot)

    # Count existing bookings at this time slot
    booked_count = vendor.bookings
      .where(booking_date: date)
      .where("start_time <= ? AND end_time > ?", slot_time, slot_time)
      .where.not(status: 'cancelled')
      .count

    employee_count - booked_count
  end

  private

  def matches_date?(date)
    date.wday == day_of_week
  end

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
