module Api
  class VendorAvailabilitiesController < BaseController
    before_action :set_vendor
    before_action :authorize_vendor, only: [:create, :update, :destroy]
    before_action :set_availability, only: [:show, :update, :destroy]

    def index
      availabilities = @vendor.vendor_availabilities.order(:day_of_week, :start_time)
      render json: availabilities, each_serializer: VendorAvailabilitySerializer
    end

    def show
      render json: @availability, serializer: VendorAvailabilitySerializer
    end

    def create
      availability = @vendor.vendor_availabilities.build(availability_params)

      if availability.save
        render json: availability, serializer: VendorAvailabilitySerializer, status: :created
      else
        render json: { errors: availability.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @availability.update(availability_params)
        render json: @availability, serializer: VendorAvailabilitySerializer
      else
        render json: { errors: @availability.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @availability.destroy
      head :no_content
    end

    # GET /api/vendors/:vendor_id/availabilities/time_slots?date=2024-01-15
    def time_slots
      date = Date.parse(params[:date])
      slots = @vendor.available_time_slots_for_date(date)
      render json: { date: date, slots: slots }
    rescue ArgumentError => e
      render json: { error: 'Invalid date format' }, status: :bad_request
    end

    private

    def set_vendor
      @vendor = Vendor.find(params[:vendor_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Vendor not found' }, status: :not_found
    end

    def set_availability
      @availability = @vendor.vendor_availabilities.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Availability not found' }, status: :not_found
    end

    def authorize_vendor
      authenticate_request
      unless current_user&.vendor_profile == @vendor
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end

    def availability_params
      params.require(:vendor_availability).permit(:day_of_week, :start_time, :end_time, :slot_duration, :employee_count)
    end
  end
end
