module Api
  class VendorsController < BaseController
    before_action :set_vendor, only: [:show, :products, :orders, :update]
    before_action :authenticate_vendor_owner!, only: [:orders, :update]
    before_action :authenticate_request, only: [:create]

    # GET /api/vendors
    def index
      vendors = Vendor.all
      vendors = vendors.by_category(params[:category]) if params[:category].present?

      if params[:search].present?
        search_term = "%#{params[:search]}%"
        vendors = vendors.where("name ILIKE ? OR description ILIKE ?", search_term, search_term)
      end

      # Filter by price range (based on vendor's products)
      if params[:min_price].present? || params[:max_price].present?
        min_price = params[:min_price].to_i * 100 if params[:min_price].present? # Convert to cents
        max_price = params[:max_price].to_i * 100 if params[:max_price].present? # Convert to cents

        vendor_ids = Product.select(:vendor_id).distinct
        vendor_ids = vendor_ids.where('price >= ?', min_price) if min_price
        vendor_ids = vendor_ids.where('price <= ?', max_price) if max_price

        vendors = vendors.where(id: vendor_ids)
      end

      render json: vendors, each_serializer: VendorSerializer
    end

    # GET /api/vendors/:id
    def show
      render json: @vendor, serializer: VendorDetailSerializer
    end

    # GET /api/vendors/:id/products
    def products
      products = @vendor.products.includes(:product_options)
      
      render json: products, each_serializer: ProductSerializer
    end

    # GET /api/vendors/:id/orders
    def orders
      orders = @vendor.orders.includes(order_items: :product).order(created_at: :desc).map do |order|
        {
          id: order.id,
          total_cents: order.total_cents,
          status: order.status,
          payment_status: order.payment_status,
          refund_status: order.refund_status,
          refund_amount_cents: order.refund_amount_cents,
          refunded_at: order.refunded_at,
          created_at: order.created_at,
          updated_at: order.updated_at,
          customer: {
            name: order.user&.name || order.guest_name,
            email: order.user&.email || order.guest_email
          },
          line_items: order.order_items.map do |item|
            next if item.product.nil?
            
            {
              id: item.id,
              product_id: item.product_id,
              quantity: item.quantity,
              price_cents: item.price_cents,
              subtotal_cents: item.subtotal_cents,
              selected_options: item.selected_options,
              product: {
                id: item.product.id,
                name: item.product.name,
                description: item.product.description,
                images: item.product.image_urls,
                is_service: item.product.is_service,
                duration: item.product.duration
              }
            }
          end.compact
        }
      end
      render json: orders.to_json
    rescue => e
      Rails.logger.error "Error fetching orders for vendor #{@vendor.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: [].to_json, status: :ok
    end

    # POST /api/vendors
    def create
      unless current_user && current_user.role == 'vendor'
        return render_error('Only vendor users can create vendor profiles', :forbidden)
      end

      # Check if user already has a vendor profile
      if Vendor.exists?(user_id: current_user.id)
        return render_error('User already has a vendor profile', :unprocessable_entity)
      end

      vendor = Vendor.new(vendor_params)
      vendor.user_id = current_user.id

      if vendor.save
        # Automatically create Stripe Connect account for the vendor
        begin
          StripeConnectService.create_account(vendor)
          vendor.reload
          Rails.logger.info "Created Stripe Connect account for vendor: #{vendor.name} (#{vendor.stripe_account_id})"
        rescue Stripe::StripeError => e
          Rails.logger.error "Failed to create Stripe Connect account for vendor #{vendor.id}: #{e.message}"
          # Continue - vendor is created but Stripe setup can be done later
        end

        render json: vendor, serializer: VendorDetailSerializer, status: :created
      else
        render_error(vendor.errors.full_messages, :unprocessable_entity)
      end
    end

    # PATCH/PUT /api/vendors/:id
    def update
      Rails.logger.info "========== VENDOR UPDATE =========="
      Rails.logger.info "Params: #{params.inspect}"
      Rails.logger.info "Vendor params: #{vendor_params.inspect}"
      Rails.logger.info "Hero image param present: #{params[:vendor][:hero_image].present?}"
      Rails.logger.info "Hero image param class: #{params[:vendor][:hero_image].class}" if params[:vendor][:hero_image].present?

      if @vendor.update(vendor_params)
        Rails.logger.info "Vendor updated successfully"
        Rails.logger.info "Hero image attached after update: #{@vendor.hero_image.attached?}"
        render json: @vendor, serializer: VendorDetailSerializer
      else
        Rails.logger.error "Vendor update failed: #{@vendor.errors.full_messages}"
        render_error(@vendor.errors.full_messages, :unprocessable_entity)
      end
    end

    private

    def set_vendor
      @vendor = Vendor.find(params[:id])
    end

    def authenticate_vendor_owner!
      unless current_user && (current_user.role == 'vendor' && @vendor.user_id == current_user.id)
        render_error('Unauthorized access to vendor orders', :forbidden)
      end
    end

    def vendor_params
      params.require(:vendor).permit(:name, :description, :location, :hero_image, categories: [], gallery_images: [])
    end
  end
end


