module Api
  class BookingsController < BaseController
    before_action :authenticate_request
    before_action :set_vendor, only: [:index, :show]
    before_action :authorize_vendor, only: [:index, :update_status]
    before_action :set_booking, only: [:show, :update_status, :cancel]

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
  end
end
