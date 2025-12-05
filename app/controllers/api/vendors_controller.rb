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
          created_at: order.created_at,
          updated_at: order.updated_at,
          customer: {
            name: order.user.name,
            email: order.user.email
          },
          line_items: order.order_items.map do |item|
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
          end
        }
      end
      render json: orders
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
        # Update user's vendor_id reference if needed (for convenience)
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
      params.require(:vendor).permit(:name, :description, :location, :hero_image, categories: [])
    end
  end
end


