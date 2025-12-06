module Api
  class CheckoutController < BaseController
    # POST /api/checkout/sessions
    def create_session
      cart_items = current_cart.cart_items.includes(:product, :vendor)

      if cart_items.empty?
        return render_error('Cart is empty', :unprocessable_entity)
      end

      # Group items by vendor for per-vendor checkout
      vendor_groups = cart_items.group_by(&:vendor)

      # Validate all vendors can process payments
      invalid_vendors = vendor_groups.keys.reject(&:can_process_payments?)
      if invalid_vendors.any?
        vendor_names = invalid_vendors.map(&:name).join(', ')
        return render_error("The following vendors cannot accept payments yet: #{vendor_names}. They need to complete Stripe onboarding.", :unprocessable_entity)
      end

      # Check if this is a per-vendor request (single vendor checkout)
      vendor_id_param = params[:vendor_id]

      if vendor_id_param
        # Single vendor checkout
        vendor = Vendor.find(vendor_id_param)
        items = vendor_groups[vendor]

        unless items
          return render_error('No items for this vendor in cart', :bad_request)
        end

        session = create_vendor_checkout_session(vendor, items, current_cart, current_user)

        render json: {
          sessionId: session.id,
          url: session.url,
          vendorId: vendor.id,
          vendorName: vendor.name
        }
      else
        # Multi-vendor checkout - create session for each vendor
        sessions = vendor_groups.map do |vendor, items|
          session = create_vendor_checkout_session(vendor, items, current_cart, current_user)

          {
            vendorId: vendor.id,
            vendorName: vendor.name,
            sessionId: session.id,
            url: session.url,
            totalCents: items.sum(&:subtotal)
          }
        end

        render json: { sessions: sessions }
      end
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

      # TODO: Add idempotency check with WebhookEvent model
      # if WebhookEvent.exists?(stripe_event_id: event['id'])
      #   return render json: { received: true, duplicate: true }
      # end

      case event['type']
      when 'checkout.session.completed'
        session = event['data']['object']
        process_successful_payment(session)

      when 'payment_intent.succeeded'
        payment_intent = event['data']['object']
        handle_payment_intent_succeeded(payment_intent)

      when 'payment_intent.payment_failed'
        payment_intent = event['data']['object']
        handle_payment_failed(payment_intent)

      when 'account.updated'
        account = event['data']['object']
        handle_account_updated(account)

      when 'charge.refunded'
        charge = event['data']['object']
        handle_charge_refunded(charge)
      end

      # Log webhook event
      create_webhook_event_log(event)

      render json: { received: true }
    end

    private

    def create_vendor_checkout_session(vendor, items, cart, user)
      total_cents = items.sum(&:subtotal)
      fee_cents = calculate_application_fee(total_cents)
      fee_percent = ENV.fetch('STRIPE_APPLICATION_FEE_PERCENT', '10.0').to_f

      line_items = items.map do |item|
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: item.product.name,
              description: "#{vendor.name} - #{format_options(item.selected_options)}",
              metadata: {
                vendor_id: vendor.id,
                product_id: item.product_id,
                selected_options: item.selected_options.to_json
              }
            },
            unit_amount: item.product.price
          },
          quantity: item.quantity
        }
      end

      # Create session with Direct Charges to vendor's Stripe account
      Stripe::Checkout::Session.create({
        payment_method_types: ['card'],
        line_items: line_items,
        mode: 'payment',
        payment_intent_data: {
          application_fee_amount: fee_cents,
          transfer_data: {
            destination: vendor.stripe_account_id
          }
        },
        success_url: "#{frontend_url}/checkout/success?session_id={CHECKOUT_SESSION_ID}&vendor_id=#{vendor.id}",
        cancel_url: "#{frontend_url}/checkout/cancel",
        metadata: {
          cart_id: cart.id,
          user_id: user&.id,
          vendor_id: vendor.id,
          application_fee_cents: fee_cents,
          platform_fee_percent: fee_percent
        }
      })
    end

    def calculate_application_fee(amount_cents)
      StripeConnectService.calculate_application_fee(amount_cents)
    end

    def process_successful_payment(session)
      cart = Cart.find(session['metadata']['cart_id'])
      user = User.find_by(id: session['metadata']['user_id'])
      vendor_id = session['metadata']['vendor_id']

      return unless cart && user

      if vendor_id
        # Single vendor order from per-vendor checkout
        vendor = Vendor.find(vendor_id)
        items = cart.cart_items.where(vendor_id: vendor_id)

        create_order_from_session(user, vendor, items, session)
      else
        # Legacy multi-vendor checkout (backward compatibility)
        cart.items_grouped_by_vendor.each do |vid, items|
          vendor = Vendor.find(vid)
          create_order_from_session(user, vendor, items, session)
        end
      end

      # Clear cart items for this vendor only (if vendor_id present) or all items
      if vendor_id
        cart.cart_items.where(vendor_id: vendor_id).destroy_all
      else
        cart.cart_items.destroy_all
      end
    end

    def create_order_from_session(user, vendor, items, session)
      total_cents = items.sum(&:subtotal)
      fee_cents = session['metadata']['application_fee_cents'].to_i
      fee_percent = session['metadata']['platform_fee_percent'].to_f

      order = user.orders.create!(
        vendor: vendor,
        total_cents: total_cents,
        status: 'confirmed',
        stripe_checkout_session_id: session['id'],
        stripe_payment_intent_id: session['payment_intent'],
        stripe_charge_id: retrieve_charge_id(session),
        application_fee_cents: fee_cents,
        platform_fee_percent: fee_percent,
        payment_status: 'succeeded'
      )

      order.create_from_cart_items!(items)

      # Trigger webhook to frontend or external system for this vendor order
      trigger_vendor_webhook(order)

      order
    end

    def retrieve_charge_id(session)
      # Get the charge ID from the payment intent
      return nil unless session['payment_intent']

      payment_intent = Stripe::PaymentIntent.retrieve(session['payment_intent'])
      payment_intent.charges.data.first&.id
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to retrieve charge ID: #{e.message}"
      nil
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

    def handle_payment_intent_succeeded(payment_intent)
      order = Order.find_by(stripe_payment_intent_id: payment_intent['id'])
      return unless order

      order.mark_payment_succeeded!
      Rails.logger.info "Payment succeeded for Order ##{order.id}"
    end

    def handle_payment_failed(payment_intent)
      order = Order.find_by(stripe_payment_intent_id: payment_intent['id'])
      return unless order

      order.mark_payment_failed!
      Rails.logger.error "Payment failed for Order ##{order.id}: #{payment_intent['last_payment_error']&.dig('message')}"

      # Optionally notify user via email or push notification
      # UserMailer.payment_failed(order).deliver_later
    end

    def handle_account_updated(account)
      vendor = Vendor.find_by(stripe_account_id: account['id'])
      return unless vendor

      StripeConnectService.update_vendor_from_account(vendor, account)
      Rails.logger.info "Stripe account updated for Vendor #{vendor.name}"
    end

    def handle_charge_refunded(charge)
      order = Order.find_by(stripe_charge_id: charge['id'])
      return unless order

      order.update!(payment_status: 'refunded')
      Rails.logger.info "Charge refunded for Order ##{order.id}"

      # Optionally notify vendor and customer
    end

    def create_webhook_event_log(event)
      # Simple in-memory log for now
      # In production, consider creating a WebhookEvent model to track events
      Rails.logger.info "Webhook received: #{event['type']} - #{event['id']}"
    rescue => e
      Rails.logger.error "Failed to log webhook event: #{e.message}"
    end

    def frontend_url
      ENV.fetch('FRONTEND_URL', 'http://localhost:3001')
    end
  end
end


