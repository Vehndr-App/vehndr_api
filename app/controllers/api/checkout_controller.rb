module Api
  class CheckoutController < BaseController
    skip_before_action :verify_authenticity_token, only: [:webhook], if: -> { defined?(verify_authenticity_token) }
    skip_before_action :authenticate_request, only: [:webhook], if: -> { defined?(authenticate_request) }

    # POST /api/checkout/sessions
    def create_session
      cart_items = current_cart.cart_items.includes(:product, :vendor)
      
      if cart_items.empty?
        return render_error('Cart is empty', :unprocessable_entity)
      end

      # Group items by vendor for checkout
      vendor_groups = cart_items.group_by(&:vendor)
      
      # For now, we'll create a single checkout session
      # In production, you might want separate sessions per vendor
      line_items = cart_items.map do |item|
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: item.product.name,
              description: "#{item.vendor.name} - #{format_options(item.selected_options)}",
              metadata: {
                vendor_id: item.vendor_id,
                product_id: item.product_id,
                selected_options: item.selected_options.to_json
              }
            },
            unit_amount: item.product.price
          },
          quantity: item.quantity
        }
      end

      session = Stripe::Checkout::Session.create({
        payment_method_types: ['card'],
        line_items: line_items,
        mode: 'payment',
        success_url: "#{frontend_url}/checkout/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "#{frontend_url}/checkout/cancel",
        metadata: {
          cart_id: current_cart.id,
          user_id: current_user&.id
        }
      })

      render json: { 
        sessionId: session.id,
        url: session.url
      }
    rescue Stripe::StripeError => e
      render_error(e.message, :unprocessable_entity)
    end

    # GET /api/checkout/success
    def success
      session_id = params[:session_id]
      
      begin
        session = Stripe::Checkout::Session.retrieve(session_id)
        
        if session.payment_status == 'paid'
          process_successful_payment(session)
          render json: { 
            message: 'Payment successful',
            orderId: session.metadata['order_id']
          }
        else
          render_error('Payment not completed', :unprocessable_entity)
        end
      rescue Stripe::StripeError => e
        render_error(e.message, :unprocessable_entity)
      end
    end

    # GET /api/checkout/cancel
    def cancel
      render json: { message: 'Checkout cancelled' }
    end

    # POST /api/checkout/webhook
    def webhook
      payload = request.body.read
      sig_header = request.headers['Stripe-Signature']
      endpoint_secret = Rails.application.credentials.stripe[:webhook_secret]

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, endpoint_secret
        )
      rescue JSON::ParserError, Stripe::SignatureVerificationError => e
        return render_error('Invalid webhook', :bad_request)
      end

      case event['type']
      when 'checkout.session.completed'
        session = event['data']['object']
        process_successful_payment(session)
      end

      render json: { received: true }
    end

    private

    def process_successful_payment(session)
      cart = Cart.find(session['metadata']['cart_id'])
      user = User.find_by(id: session['metadata']['user_id'])
      
      return unless cart && user

      # Create orders for each vendor
      cart.items_grouped_by_vendor.each do |vendor_id, items|
        vendor = Vendor.find(vendor_id)
        
        order = user.orders.create!(
          vendor: vendor,
          total_cents: items.sum(&:subtotal),
          status: 'confirmed',
          stripe_checkout_session_id: session['id'],
          stripe_payment_intent_id: session['payment_intent']
        )

        order.create_from_cart_items!(items)
        
        # Trigger webhook to frontend or external system for this vendor order
        trigger_vendor_webhook(order)
      end

      # Clear the cart
      cart.cart_items.destroy_all
    end

    def trigger_vendor_webhook(order)
      # Broadcast to ActionCable channel for real-time dashboard updates
      VendorOrdersChannel.broadcast_to(
        order.vendor,
        {
          event: 'order.created',
          order: {
            id: order.id,
            total_cents: order.total_cents,
            status: order.status,
            created_at: order.created_at,
            user: {
              name: order.user.name,
              email: order.user.email
            }
          }
        }
      )
      
      Rails.logger.info "ActionCable broadcast: New Order ##{order.id} for Vendor #{order.vendor.name}"
    end

    def format_options(options)
      return '' if options.blank?
      options.map { |k, v| "#{k.humanize}: #{v}" }.join(', ')
    end

    def frontend_url
      Rails.env.production? ? 'https://your-frontend.com' : 'http://localhost:3000'
    end
  end
end


