module Api
  class EventsController < ApplicationController
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
  end
end


