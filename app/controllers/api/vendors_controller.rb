module Api
  class VendorsController < BaseController
    before_action :set_vendor, only: [:show, :products, :orders]
    before_action :authenticate_vendor_owner!, only: [:orders]

    # GET /api/vendors
    def index
      vendors = Vendor.all
      vendors = vendors.by_category(params[:category]) if params[:category].present?
      
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
      orders = @vendor.orders.order(created_at: :desc).map do |order|
        {
          id: order.id,
          total_cents: order.total_cents,
          status: order.status,
          created_at: order.created_at,
          updated_at: order.updated_at
        }
      end
      render json: orders
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
  end
end


