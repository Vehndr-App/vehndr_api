module Api
  class EventCoordinatorsController < BaseController
    before_action :set_coordinator, only: [:show]

    # GET /api/coordinators
    def index
      coordinators = EventCoordinator.all
      render json: coordinators, each_serializer: EventCoordinatorSerializer
    end

    # GET /api/coordinators/:id
    def show
      render json: @coordinator, serializer: EventCoordinatorSerializer
    end

    private

    def set_coordinator
      @coordinator = EventCoordinator.find(params[:id])
    end
  end
end


