module Api
  class EventsController < BaseController
    before_action :authenticate_request, only: [:create_from_url, :my_events, :dashboard, :recommended_vendors]

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
      unless current_user.role == 'coordinator'
        return render json: { error: 'Only coordinators can access this endpoint' }, status: :forbidden
      end

      # Auto-create coordinator profile if it doesn't exist
      coordinator = current_user.coordinator_profile
      unless coordinator
        coordinator = EventCoordinator.create!(
          user: current_user,
          name: current_user.name || current_user.email
        )
      end

      events = coordinator.events.order(start_date: :desc)
      render :index, locals: { events: }
    end

    def create_from_url
      unless current_user.role == 'coordinator'
        return render json: { error: 'Only coordinators can create events' }, status: :forbidden
      end

      # Get or create coordinator profile for current user
      coordinator = current_user.coordinator_profile
      unless coordinator
        coordinator = EventCoordinator.create!(
          user: current_user,
          name: current_user.name || current_user.email
        )
      end

      url = params[:url]
      unless url.present?
        return render json: { error: 'URL is required' }, status: :unprocessable_entity
      end

      begin
        event_data = EventFromUrlService.call(url)
        event = coordinator.events.create!(event_data)
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
      unless current_user.role == 'coordinator'
        return render json: { error: 'Only coordinators can access event dashboards' }, status: :forbidden
      end

      event = Event.find(params[:id])

      # Verify this event belongs to the current coordinator
      coordinator = current_user.coordinator_profile
      unless event.coordinator_id == coordinator&.id
        return render json: { error: 'Not authorized to view this event' }, status: :forbidden
      end

      # Get vendors participating in this event with their sales data
      vendors_data = event.vendors.map do |vendor|
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
          id: event.id,
          name: event.name,
          description: event.description,
          location: event.location,
          startDate: event.start_date,
          endDate: event.end_date,
          image: event.image,
          category: event.category,
          attendees: event.attendees,
          status: event.status
        },
        vendors: vendors_data,
        totalSales: total_event_sales
      }
    end

    def recommended_vendors
      unless current_user.role == 'coordinator'
        return render json: { error: 'Only coordinators can access recommendations' }, status: :forbidden
      end

      event = Event.find(params[:id])

      # Verify this event belongs to the current coordinator
      coordinator = current_user.coordinator_profile
      unless event.coordinator_id == coordinator&.id
        return render json: { error: 'Not authorized to view this event' }, status: :forbidden
      end

      # Use nearest neighbors to find vendors with similar embeddings
      vendors = Vendor.nearest_neighbors(:embedding, event.embedding, distance: 'euclidean').first(3).map do |vendor|
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
  end
end


