module Api
  class CheckoutController < BaseController
    # POST /api/checkout/payment_intent
    def create_payment_intent
      vendor_id = params[:vendorId] || params[:vendor_id]

      unless vendor_id
        return render_error('Vendor ID required', :bad_request)
      end

      vendor = Vendor.find(vendor_id)

      # Get items from params or from cart
      items_param = params[:items]

      if items_param.present?
        # Calculate from provided items
        total_cents = 0
        items_param.each do |item|
          product_id = item[:productId] || item['productId']
          product = Product.find_by(id: product_id)

          unless product
            return render_error("Product not found: #{product_id}", :not_found)
          end

          quantity = (item[:quantity] || item['quantity']).to_i
          total_cents += product.price * quantity
        end
      else
        # Get from cart
        cart_items = current_cart.cart_items.where(vendor_id: vendor_id).includes(:product)
        if cart_items.empty?
          return render_error('No items for this vendor in cart', :bad_request)
        end
        total_cents = cart_items.sum(&:subtotal)
      end

      # Calculate application fee
      fee_cents = calculate_application_fee(total_cents)
      fee_percent = ENV.fetch('STRIPE_APPLICATION_FEE_PERCENT', '10.0').to_f

      # Create PaymentIntent with connected account
      payment_intent_params = {
        amount: total_cents,
        currency: 'usd',
        application_fee_amount: fee_cents,
        transfer_data: {
          destination: vendor.stripe_account_id
        },
        metadata: {
          vendor_id: vendor.id,
          vendor_name: vendor.name,
          cart_id: current_cart.id,
          user_id: current_user&.id,
          application_fee_cents: fee_cents,
          platform_fee_percent: fee_percent
        },
        automatic_payment_methods: {
          enabled: true
        },
      }

      # For guest checkout, configure billing details collection
      unless current_user
        payment_intent_params[:payment_method_options] = {
          card: {
            setup_future_usage: nil
          }
        }
      end

      payment_intent = Stripe::PaymentIntent.create(payment_intent_params)

      render json: {
        clientSecret: payment_intent.client_secret,
        paymentIntentId: payment_intent.id,
        vendorId: vendor.id,
        vendorName: vendor.name,
        totalCents: total_cents
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe PaymentIntent Error: #{e.message}"
      render_error(e.message, :unprocessable_entity)
    rescue ActiveRecord::RecordNotFound => e
      render_error("Resource not found: #{e.message}", :not_found)
    end

    # POST /api/checkout/confirm_payment
    def confirm_payment
      payment_intent_id = params[:paymentIntentId] || params[:payment_intent_id]

      unless payment_intent_id
        return render_error('Payment Intent ID required', :bad_request)
      end

      # Retrieve the PaymentIntent to verify status
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)

      if payment_intent.status == 'succeeded'
        # Create order from the payment intent
        vendor_id = payment_intent.metadata['vendor_id']
        cart_id = payment_intent.metadata['cart_id']
        user_id = payment_intent.metadata['user_id']

        cart = Cart.find(cart_id)
        user = User.find_by(id: user_id)
        vendor = Vendor.find(vendor_id)

        # Get cart items for this vendor
        cart_items = cart.cart_items.where(vendor_id: vendor_id).includes(:product)

        if cart_items.empty?
          return render_error('No items found for this vendor', :bad_request)
        end

        # Create the order
        order = create_order_from_payment_intent(user, vendor, cart_items, payment_intent)

        if order.persisted?
          # Clear cart items for this vendor
          cart_items.destroy_all

          render json: {
            success: true,
            orderId: order.id,
            message: 'Payment successful'
          }
        else
          Rails.logger.error "Order creation failed: #{order.errors.full_messages.join(', ')}"
          return render_error("Failed to create order: #{order.errors.full_messages.join(', ')}", :unprocessable_entity)
        end
      else
        render_error("Payment not completed. Status: #{payment_intent.status}", :unprocessable_entity)
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe Error in confirm_payment: #{e.message}"
      render_error(e.message, :unprocessable_entity)
    rescue ActiveRecord::RecordNotFound => e
      render_error("Resource not found: #{e.message}", :not_found)
    end

    # POST /api/checkout/sessions
    def create_session
      cart_items = current_cart.cart_items.includes(:product, :vendor)

      if cart_items.empty?
        return render_error('Cart is empty', :unprocessable_entity)
      end

      # Group items by vendor for per-vendor checkout
      vendor_groups = cart_items.group_by(&:vendor)

      # Check if this is a demo checkout request (development only)
      demo_mode = Rails.env.development? && params[:demo_mode] == true

      unless demo_mode
        # Validate all vendors can process payments
        invalid_vendors = vendor_groups.keys.reject(&:can_process_payments?)
        if invalid_vendors.any?
          vendor_names = invalid_vendors.map(&:name).join(', ')
          error_msg = "The following vendors cannot accept payments yet: #{vendor_names}. They need to complete Stripe onboarding."
          Rails.logger.error "Checkout Error: #{error_msg}"
          return render_error(error_msg, :unprocessable_entity)
        end
      end

      # Check if this is a per-vendor request (single vendor checkout)
      vendor_id_param = params[:vendorId] || params[:vendor_id]

      Rails.logger.info "Checkout Debug: vendor_id_param = #{vendor_id_param.inspect}, params keys = #{params.keys.inspect}, demo_mode = #{demo_mode}"

      if vendor_id_param
        # Single vendor checkout
        vendor = Vendor.find(vendor_id_param)
        items = vendor_groups[vendor]

        unless items
          return render_error('No items for this vendor in cart', :bad_request)
        end

        # Demo mode - create a demo checkout session URL
        if demo_mode
          demo_session_id = "demo_cs_#{SecureRandom.hex(16)}"
          total_cents = items.sum(&:subtotal)
          
          render json: {
            sessionId: demo_session_id,
            url: "#{frontend_url}/checkout/demo?session_id=#{demo_session_id}&vendor_id=#{vendor.id}&total=#{total_cents}",
            vendorId: vendor.id,
            vendorName: vendor.name,
            demoMode: true,
            totalCents: total_cents
          }
          return
        end

        session = create_vendor_checkout_session(vendor, items, current_cart, current_user)

        Rails.logger.info "Stripe Session Created: ID=#{session.id}, URL=#{session.url.inspect}"

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

    # POST /api/checkout/in_person
    # For in-person/terminal checkout
    def create_in_person
      vendor_id = params[:vendor_id] || current_user&.vendor_profile&.id
      items = params[:items] || []
      custom_items = params[:custom_items] || []
      payment_method = params[:payment_method] || 'tap_to_pay'
      
      unless vendor_id
        return render_error('Vendor ID required', :bad_request)
      end

      vendor = Vendor.find(vendor_id)
      
      # In development, allow demo mode for testing
      demo_mode = Rails.env.development? || params[:demo_mode] == true
      
      unless demo_mode || vendor.can_process_payments?
        return render_error('Vendor cannot process payments yet. Complete Stripe onboarding first.', :unprocessable_entity)
      end

      if items.empty? && custom_items.empty?
        return render_error('No items provided', :bad_request)
      end

      # Calculate totals
      total_cents = 0
      line_items = []

      # Process regular product items
      items.each do |item|
        product = Product.find(item['product_id'])
        quantity = item['quantity'].to_i
        subtotal = product.price * quantity
        total_cents += subtotal

        line_items << {
          product_id: product.id,
          product_name: product.name,
          price_cents: product.price,
          quantity: quantity,
          subtotal_cents: subtotal
        }
      end

      # Process custom/ad-hoc items (from keypad)
      custom_items.each do |item|
        quantity = item['quantity'].to_i
        price_cents = item['price'].to_i
        subtotal = price_cents * quantity
        total_cents += subtotal

        line_items << {
          product_id: nil,
          product_name: item['name'] || 'Custom Item',
          price_cents: price_cents,
          quantity: quantity,
          subtotal_cents: subtotal,
          is_custom: true
        }
      end

      # Create order directly (in-person payment is assumed to be completed)
      # For in-person sales, we use a placeholder guest email since there's no customer account
      order = Order.create!(
        vendor: vendor,
        user: nil, # In-person sales don't have a customer user
        guest_email: "pos_sale_#{Time.current.to_i}@inperson.local", # Placeholder for POS sales
        guest_name: params[:customer_name] || 'Walk-in Customer',
        total_cents: total_cents,
        status: 'completed',
        payment_status: 'succeeded',
        payment_method: payment_method,
        is_in_person: true,
        stripe_payment_intent_id: "in_person_#{SecureRandom.hex(16)}"
      )

      # Create order items
      line_items.each do |item_data|
        order.order_items.create!(
          product_id: item_data[:product_id],
          product_name: item_data[:product_name],
          price_cents: item_data[:price_cents],
          quantity: item_data[:quantity],
          is_custom: item_data[:is_custom] || false
        )
      end

      # Broadcast to vendor's orders channel
      ActionCable.server.broadcast(
        "vendor_orders_#{vendor.id}",
        {
          type: 'new_order',
          order: order.as_json(
            include: {
              order_items: { only: [:id, :product_name, :price_cents, :quantity] }
            }
          )
        }
      )

      render json: {
        success: true,
        order_id: order.id,
        total_cents: total_cents,
        message: 'Payment processed successfully'
      }
    rescue ActiveRecord::RecordNotFound => e
      render_error("Product not found: #{e.message}", :not_found)
    rescue => e
      Rails.logger.error "In-person checkout error: #{e.message}\n#{e.backtrace.join("\n")}"
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
      endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) || ENV['VEHNDR_STRIPE_WEBHOOK_SECRET']

      Rails.logger.info "=== Stripe Webhook Received ==="
      Rails.logger.info "Signature present: #{sig_header.present?}"
      Rails.logger.info "Endpoint secret configured: #{endpoint_secret.present?}"

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, endpoint_secret
        )
        Rails.logger.info "Webhook event constructed successfully: #{event['type']} - #{event['id']}"
      rescue JSON::ParserError => e
        Rails.logger.error "Webhook JSON parse error: #{e.message}"
        return render_error('Invalid webhook - JSON parse error', :bad_request)
      rescue Stripe::SignatureVerificationError => e
        Rails.logger.error "Webhook signature verification failed: #{e.message}"
        return render_error('Invalid webhook - signature verification failed', :bad_request)
      end

      # TODO: Add idempotency check with WebhookEvent model
      # if WebhookEvent.exists?(stripe_event_id: event['id'])
      #   return render json: { received: true, duplicate: true }
      # end

      case event['type']
      when 'checkout.session.completed'
        session = event['data']['object']
        Rails.logger.info "Processing checkout.session.completed"
        process_successful_payment(session)

      when 'payment_intent.succeeded'
        payment_intent = event['data']['object']
        Rails.logger.info "Processing payment_intent.succeeded"
        handle_payment_intent_succeeded(payment_intent)

      when 'payment_intent.payment_failed'
        payment_intent = event['data']['object']
        Rails.logger.info "Processing payment_intent.payment_failed"
        handle_payment_failed(payment_intent)

      when 'account.updated'
        account = event['data']['object']
        Rails.logger.info "Processing account.updated for account: #{account['id']}"
        handle_account_updated(account)

      when 'charge.refunded'
        charge = event['data']['object']
        Rails.logger.info "Processing charge.refunded"
        handle_charge_refunded(charge)
      else
        Rails.logger.info "Unhandled webhook event type: #{event['type']}"
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

      # Build session params
      session_params = {
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
      }

      # For guest checkout, collect email during Stripe checkout
      unless user
        session_params[:customer_email] = nil # Let Stripe collect it
        session_params[:billing_address_collection] = 'required'
        session_params[:phone_number_collection] = { enabled: true }
      end

      # Create session with Direct Charges to vendor's Stripe account
      Stripe::Checkout::Session.create(session_params)
    end

    def calculate_application_fee(amount_cents)
      StripeConnectService.calculate_application_fee(amount_cents)
    end

    def process_successful_payment(session)
      cart = Cart.find(session['metadata']['cart_id'])
      user = User.find_by(id: session['metadata']['user_id'])
      vendor_id = session['metadata']['vendor_id']

      return unless cart

      # Extract guest info from Stripe if no user
      guest_data = nil
      unless user
        guest_data = extract_guest_data_from_session(session)
        return unless guest_data[:email].present?
      end

      if vendor_id
        # Single vendor order from per-vendor checkout
        vendor = Vendor.find(vendor_id)
        items = cart.cart_items.where(vendor_id: vendor_id)

        create_order_from_session(user, vendor, items, session, guest_data)
      else
        # Legacy multi-vendor checkout (backward compatibility)
        cart.items_grouped_by_vendor.each do |vid, items|
          vendor = Vendor.find(vid)
          create_order_from_session(user, vendor, items, session, guest_data)
        end
      end

      # Clear cart items for this vendor only (if vendor_id present) or all items
      if vendor_id
        cart.cart_items.where(vendor_id: vendor_id).destroy_all
      else
        cart.cart_items.destroy_all
      end
    end

    def create_order_from_payment_intent(user, vendor, items, payment_intent)
      total_cents = items.sum(&:subtotal)
      fee_cents = payment_intent.metadata['application_fee_cents'].to_i
      fee_percent = payment_intent.metadata['platform_fee_percent'].to_f

      order_params = {
        vendor: vendor,
        total_cents: total_cents,
        status: 'confirmed',
        stripe_payment_intent_id: payment_intent.id,
        stripe_charge_id: payment_intent.latest_charge,
        application_fee_cents: fee_cents,
        platform_fee_percent: fee_percent,
        payment_status: 'succeeded'
      }

      if user
        order_params[:user] = user
      else
        # For guest checkout, extract email from billing details
        # Fetch the charge to get billing details
        guest_email = 'guest@vehndr.local'
        guest_name = 'Guest Customer'

        if payment_intent.latest_charge.present?
          begin
            charge = Stripe::Charge.retrieve(payment_intent.latest_charge)
            billing_details = charge.billing_details
            guest_email = billing_details['email'] || guest_email
            guest_name = billing_details['name'] || guest_name
          rescue => e
            Rails.logger.error "Failed to retrieve charge billing details: #{e.message}"
          end
        end

        order_params[:guest_email] = guest_email
        order_params[:guest_name] = guest_name
      end

      order = Order.create(order_params)

      if order.persisted?
        order.create_from_cart_items!(items)
        # Broadcast to vendor
        # TODO: Fix Solid Cable serialization issue with custom vendor IDs
        # trigger_vendor_webhook(order)
      else
        Rails.logger.error "Order creation validation failed: #{order.errors.full_messages.join(', ')}"
      end

      order
    end

    def create_order_from_session(user, vendor, items, session, guest_data = nil)
      total_cents = items.sum(&:subtotal)
      fee_cents = session['metadata']['application_fee_cents'].to_i
      fee_percent = session['metadata']['platform_fee_percent'].to_f

      order_params = {
        vendor: vendor,
        total_cents: total_cents,
        status: 'confirmed',
        stripe_checkout_session_id: session['id'],
        stripe_payment_intent_id: session['payment_intent'],
        stripe_charge_id: retrieve_charge_id(session),
        application_fee_cents: fee_cents,
        platform_fee_percent: fee_percent,
        payment_status: 'succeeded'
      }

      if user
        order_params[:user] = user
      elsif guest_data
        order_params[:guest_email] = guest_data[:email]
        order_params[:guest_name] = guest_data[:name]
        order_params[:guest_phone] = guest_data[:phone]
      end

      order = Order.create!(order_params)
      order.create_from_cart_items!(items)

      # Trigger webhook to frontend or external system for this vendor order
      # TODO: Fix Solid Cable serialization issue with custom vendor IDs
      # trigger_vendor_webhook(order)

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
      # Extract all values as primitives to avoid Solid Cable serialization issues
      vendor_id_str = order.vendor_id.to_s
      order_id_str = order.id.to_s
      total = order.total_cents.to_i
      status_str = order.status.to_s
      created_str = order.created_at.iso8601.to_s
      customer_name_str = order.customer_name.to_s
      customer_email_str = order.customer_email.to_s

      message = {
        'event' => 'order.created',
        'order' => {
          'id' => order_id_str,
          'total_cents' => total,
          'status' => status_str,
          'created_at' => created_str,
          'customer' => {
            'name' => customer_name_str,
            'email' => customer_email_str
          }
        }
      }

      ActionCable.server.broadcast("vendor_orders_#{vendor_id_str}", message)

      Rails.logger.info "ActionCable broadcast: New Order ##{order_id_str} for Vendor #{vendor_id_str}"
    end

    def extract_guest_data_from_session(stripe_session)
      # Retrieve full session details to get customer info
      session = Stripe::Checkout::Session.retrieve(
        stripe_session['id'],
        expand: ['customer_details']
      )

      customer_details = session.customer_details || {}

      {
        email: session.customer_email || customer_details['email'],
        name: customer_details['name'],
        phone: customer_details['phone']
      }
    rescue => e
      Rails.logger.error "Failed to extract guest data: #{e.message}"
      { email: nil, name: nil, phone: nil }
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
      Rails.logger.info "=== Handling account.updated webhook ==="
      Rails.logger.info "Account ID: #{account['id']}"
      Rails.logger.info "Charges enabled: #{account['charges_enabled']}"
      Rails.logger.info "Payouts enabled: #{account['payouts_enabled']}"
      Rails.logger.info "Details submitted: #{account['details_submitted']}"

      vendor = Vendor.find_by(stripe_account_id: account['id'])

      if vendor.nil?
        Rails.logger.warn "No vendor found with stripe_account_id: #{account['id']}"
        return
      end

      Rails.logger.info "Found vendor: #{vendor.name} (ID: #{vendor.id})"
      Rails.logger.info "Vendor before update - charges_enabled: #{vendor.stripe_charges_enabled}, details_submitted: #{vendor.stripe_details_submitted}"

      StripeConnectService.update_vendor_from_account(vendor, account)
      vendor.reload

      Rails.logger.info "Vendor after update - charges_enabled: #{vendor.stripe_charges_enabled}, details_submitted: #{vendor.stripe_details_submitted}"
      Rails.logger.info "Stripe account successfully updated for Vendor #{vendor.name}"
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


