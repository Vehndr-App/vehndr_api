module Api
  class BookingsController < BaseController
    before_action :authenticate_request
    before_action :set_vendor, only: [:index, :show]
    before_action :authorize_vendor, only: [:index, :update_status]
    before_action :set_booking, only: [:show, :update_status, :cancel, :reschedule]
    before_action :authorize_booking_owner, only: [:cancel, :reschedule]

    # GET /api/vendors/:vendor_id/bookings
    def index
      bookings = @vendor.bookings.includes(:product, :employee).order(booking_date: :desc, start_time: :desc)

      # Filter by status if provided
      bookings = bookings.by_status(params[:status]) if params[:status].present?

      # Filter by date range if provided
      if params[:start_date].present? && params[:end_date].present?
        bookings = bookings.where(booking_date: params[:start_date]..params[:end_date])
      end

      render json: bookings, each_serializer: BookingSerializer
    end

    # GET /api/bookings/:id
    def show
      render json: @booking, serializer: BookingSerializer
    end

    # PATCH /api/bookings/:id/status
    def update_status
      if @booking.update(status: params[:status])
        render json: @booking, serializer: BookingSerializer
      else
        render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # POST /api/bookings/:id/cancel
    def cancel
      if @booking.update(status: 'cancelled')
        render json: @booking, serializer: BookingSerializer
      else
        render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH /api/bookings/:id/reschedule
    def reschedule
      # Only allow rescheduling if booking is pending or confirmed
      unless ['pending', 'confirmed'].include?(@booking.status)
        render json: { error: 'Cannot reschedule a cancelled or completed booking' }, status: :unprocessable_entity
        return
      end

      # Parse new date and time
      new_date = params[:booking_date]
      new_time = params[:start_time]

      if new_date.blank? || new_time.blank?
        render json: { error: 'Booking date and start time are required' }, status: :unprocessable_entity
        return
      end

      # Update the booking with new date/time
      if @booking.update(
        booking_date: new_date,
        start_time: new_time,
        end_time: nil, # Will be recalculated by model callback
        employee_id: nil # Will be reassigned by model callback
      )
        render json: @booking, serializer: BookingSerializer
      else
        render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # GET /api/bookings/my_bookings (for customers)
    def my_bookings
      # Get bookings for the current user through their orders
      bookings = Booking.joins(order_item: { order: :user })
                        .where(orders: { user_id: current_user.id })
                        .includes(:product, :vendor, :employee)
                        .order(booking_date: :desc, start_time: :desc)

      render json: bookings, each_serializer: BookingSerializer
    end

    private

    def set_vendor
      @vendor = Vendor.find(params[:vendor_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Vendor not found' }, status: :not_found
    end

    def set_booking
      if params[:vendor_id]
        @booking = @vendor.bookings.find(params[:id])
      else
        @booking = Booking.find(params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Booking not found' }, status: :not_found
    end

    def authorize_vendor
      unless current_user&.vendor_profile == @vendor
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end

    def authorize_booking_owner
      # Check if the current user owns this booking through their orders
      booking_user = @booking.order_item&.order&.user
      unless booking_user == current_user
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
