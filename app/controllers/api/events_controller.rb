module Api
  class EventsController < BaseController
    before_action :authenticate_request, only: [:create, :create_from_url, :my_events, :dashboard, :recommended_vendors, :update, :publish]
    before_action :require_coordinator, only: [:create, :create_from_url, :my_events, :dashboard, :recommended_vendors, :update, :publish]
    before_action :set_event, only: [:dashboard, :recommended_vendors, :update, :publish]
    before_action :authorize_event, only: [:dashboard, :recommended_vendors, :update, :publish]

    def index
      events = Event.includes(:vendors)

      if params[:vendor_id].present?
        events = events.joins(:event_vendors).where(event_vendors: { vendor_id: params[:vendor_id] })
      end

      if params[:status].present?
        events = events.where(status: params[:status])
      end

      if params[:limit].present?
        events = events.limit(params[:limit].to_i)
      end

      render :index, locals: { events: }
    end

    def show
      event = Event.includes(:vendors).find(params[:id])
      render :show, locals: { event: }
    end

    def my_events
      events = current_coordinator.events.order(start_date: :desc)
      render :index, locals: { events: }
    end

    def create
      event = current_coordinator.events.new(event_params)
      
      if event.save
        render :show, locals: { event: }, status: :created
      else
        render json: { error: 'Event creation failed', errors: event.errors.full_messages }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "Event creation error: #{e.message}\n#{e.backtrace.first(10).join("\n")}"
      render json: { error: "Server error: #{e.message}" }, status: :internal_server_error
    end

    def update
      if @event.update(event_params)
        render :show, locals: { event: @event }
      else
        render json: { error: 'Event update failed', errors: @event.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def publish
      if @event.update(status: 'upcoming')
        render :show, locals: { event: @event }
      else
        render json: { error: 'Failed to publish event', errors: @event.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def create_from_url
      url = params[:url]
      unless url.present?
        return render json: { error: 'URL is required' }, status: :unprocessable_entity
      end

      begin
        event_data = EventFromUrlService.call(url)
        event = current_coordinator.events.create!(event_data)
        render :show, locals: { event: }, status: :created
      rescue EventFromUrlService::InvalidUrlError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue EventFromUrlService::ScrapingError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: 'Event creation failed', errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def dashboard
      # Get vendors participating in this event with their sales data
      vendors_data = @event.vendors.map do |vendor|
        # Calculate total sales for this vendor at this event
        total_sales = Order.joins(:order_items)
                          .where(order_items: { vendor_id: vendor.id })
                          .where(status: ['confirmed', 'completed'])
                          .sum('order_items.subtotal_cents')

        {
          id: vendor.id,
          name: vendor.name,
          description: vendor.description,
          heroImage: vendor.hero_image,
          location: vendor.location,
          totalSales: total_sales
        }
      end

      # Calculate total sales across all vendors
      total_event_sales = vendors_data.sum { |v| v[:totalSales] }

      render json: {
        event: {
          id: @event.id,
          name: @event.name,
          description: @event.description,
          location: @event.location,
          startDate: @event.start_date,
          endDate: @event.end_date,
          image: @event.image,
          category: @event.category,
          attendees: @event.attendees,
          status: @event.status
        },
        vendors: vendors_data,
        totalSales: total_event_sales
      }
    end

    def recommended_vendors
      # Use nearest neighbors to find vendors with similar embeddings
      vendors = Vendor.nearest_neighbors(:embedding, @event.embedding, distance: 'euclidean').first(3).map do |vendor|
        {
          id: vendor.id,
          name: vendor.name,
          description: vendor.description,
          heroImage: vendor.hero_image_url,
          location: vendor.location
        }
      end

      render json: { vendors: vendors }
    end

    private

    def require_coordinator
      unless current_user&.role == 'coordinator'
        render json: { error: 'Only coordinators can access this resource' }, status: :forbidden
        return
      end
    end

    def current_coordinator
      @current_coordinator ||= begin
        coordinator = current_user.coordinator_profile
        unless coordinator
          coordinator = EventCoordinator.create!(
            user: current_user,
            name: current_user.name || current_user.email
          )
        end
        coordinator
      end
    end

    def set_event
      @event = Event.find(params[:id])
    end

    def authorize_event
      unless @event.coordinator_id == current_coordinator.id
        render json: { error: 'Not authorized to access this event' }, status: :forbidden
        return
      end
    end

    def event_params
      params.permit(
        :name, :description, :location, :start_date, :end_date, 
        :image, :category, :attendees, :status, :theme, :cost_per_person,
        :capacity, :guests_can_invite, :dress_code, :playlist_link,
        :registry_link, :external_link
      )
    end
  end
end


