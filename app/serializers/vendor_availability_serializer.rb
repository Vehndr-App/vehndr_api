class VendorAvailabilitySerializer < ActiveModel::Serializer
  attributes :id, :vendor_id, :day_of_week, :start_time, :end_time, :slot_duration, :employee_count, :day_name

  def day_name
    Date::DAYNAMES[object.day_of_week]
  end

  def start_time
    object.start_time.strftime('%I:%M %p')
  end

  def end_time
    object.end_time.strftime('%I:%M %p')
  end
end
