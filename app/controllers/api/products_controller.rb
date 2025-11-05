module Api
  class ProductsController < BaseController
    before_action :set_product, only: [:show]

    # GET /api/products
    def index
      products = Product.includes(:vendor, :product_options)
      products = products.where(vendor_id: params[:vendor_id]) if params[:vendor_id].present?
      products = products.services_only if params[:services_only] == 'true'
      products = products.products_only if params[:products_only] == 'true'
      
      render json: products, each_serializer: ProductWithVendorSerializer
    end

    # GET /api/products/:id
    def show
      render json: @product, serializer: ProductDetailSerializer
    end

    private

    def set_product
      @product = Product.includes(:vendor, :product_options).find(params[:id])
    end
  end
end


