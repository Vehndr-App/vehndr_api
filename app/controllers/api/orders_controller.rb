module Api
  class OrdersController < BaseController
    before_action :authenticate_request
    before_action :set_order, only: [:complete]
    before_action :authorize_vendor!, only: [:complete]

    # PATCH /api/orders/:id/complete
    def complete
      if @order.complete!
        render json: {
          id: @order.id,
          status: @order.status,
          message: 'Order marked as completed'
        }
      else
        render_error('Failed to complete order', :unprocessable_entity)
      end
    end

    private

    def set_order
      @order = Order.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render_error('Order not found', :not_found)
      return
    end

    def authorize_vendor!
      unless current_user&.role == 'vendor' &&
             current_user.vendor_profile.present? &&
             @order.vendor_id == current_user.vendor_profile.id
        render_error('Unauthorized to complete this order', :forbidden)
        return
      end
    end
  end
end
