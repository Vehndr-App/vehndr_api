class BookingSerializer < ActiveModel::Serializer
  attributes :id, :vendor_id, :product_id, :order_item_id, :employee_id,
             :booking_date, :start_time, :end_time, :status,
             :customer_name, :customer_email, :customer_phone,
             :created_at, :updated_at

  belongs_to :product
  belongs_to :employee, optional: true
  belongs_to :vendor

  def start_time
    object.start_time.strftime('%I:%M %p')
  end

  def end_time
    object.end_time.strftime('%I:%M %p')
  end
end
