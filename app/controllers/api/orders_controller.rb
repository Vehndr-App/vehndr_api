module Api
  class OrdersController < BaseController
    before_action :authenticate_request
    before_action :set_order, only: [:complete, :refund]
    before_action :authorize_vendor!, only: [:complete, :refund]

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

    # POST /api/orders/:id/refund
    def refund
      unless @order.refundable?
        return render_error('Order cannot be refunded', :unprocessable_entity)
      end

      # Get refund amount from params (default to full refund)
      refund_amount_cents = params[:amount_cents]&.to_i || @order.total_cents

      # Validate refund amount
      if refund_amount_cents <= 0 || refund_amount_cents > @order.total_cents
        return render_error('Invalid refund amount', :unprocessable_entity)
      end

      # Mark as pending
      @order.mark_refund_pending!

      begin
        # Create Stripe refund
        refund = Stripe::Refund.create({
          charge: @order.stripe_charge_id,
          amount: refund_amount_cents,
          reason: params[:reason] || 'requested_by_customer'
        })

        # Update order with refund details
        @order.mark_refunded!(refund.id, refund_amount_cents)

        # Broadcast update to vendor dashboard
        broadcast_order_update(@order)

        render json: {
          id: @order.id,
          refund_status: @order.refund_status,
          refund_amount_cents: @order.refund_amount_cents,
          refunded_at: @order.refunded_at,
          message: "Refund of $#{@order.refund_amount_in_dollars} processed successfully"
        }
      rescue Stripe::StripeError => e
        @order.update!(refund_status: 'none')
        render_error("Stripe refund failed: #{e.message}", :unprocessable_entity)
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

    def broadcast_order_update(order)
      ActionCable.server.broadcast(
        "vendor_orders_#{order.vendor.id}",
        {
          event: 'order.updated',
          order: {
            id: order.id,
            status: order.status,
            refund_status: order.refund_status,
            refund_amount_cents: order.refund_amount_cents,
            refunded_at: order.refunded_at
          }
        }
      )
    end
  end
end
