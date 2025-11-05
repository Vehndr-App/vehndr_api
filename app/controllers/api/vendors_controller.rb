module Api
  class VendorsController < BaseController
    before_action :set_vendor, only: [:show, :products]

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

    private

    def set_vendor
      @vendor = Vendor.find(params[:id])
    end
  end
end


