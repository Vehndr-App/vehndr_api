module Api
  class ProductsController < BaseController
    before_action :authenticate_request, only: [:create, :update, :destroy]
    before_action :set_product, only: [:show, :update, :destroy]
    before_action :authorize_vendor!, only: [:update, :destroy]

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

    # POST /api/products
    def create
      unless current_user&.role == 'vendor' && current_user.vendor_profile.present?
        return render_error('Only vendors can create products', :forbidden)
      end

      Rails.logger.info "========== PRODUCT CREATE =========="
      Rails.logger.info "Images param present: #{params[:images].present?}"
      Rails.logger.info "Images param class: #{params[:images].class}" if params[:images].present?

      @product = current_user.vendor_profile.products.build(product_params)

      if @product.save
        Rails.logger.info "Product saved with ID: #{@product.id}"
        attach_images if params[:images].present?
        Rails.logger.info "Images attached. Count: #{@product.images.count}"
        render json: @product, serializer: ProductSerializer, status: :created
      else
        render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/products/:id
    def update
      Rails.logger.info "========== PRODUCT UPDATE =========="
      Rails.logger.info "Product ID: #{@product.id}"
      Rails.logger.info "Images param present: #{params[:images].present?}"
      Rails.logger.info "Images param class: #{params[:images].class}" if params[:images].present?

      if @product.update(product_params)
        attach_images if params[:images].present?
        Rails.logger.info "Images attached. Count: #{@product.images.count}"
        render json: @product, serializer: ProductSerializer
      else
        render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/products/:id
    def destroy
      @product.destroy
      head :no_content
    end

    private

    def set_product
      @product = Product.includes(:vendor, :product_options).find(params[:id])
    end

    def authorize_vendor!
      unless current_user&.vendor_profile&.id == @product.vendor_id
        render_error('Unauthorized to modify this product', :forbidden)
      end
    end

    def product_params
      params.require(:product).permit(
        :name, :description, :price, :is_service, :duration,
        available_time_slots: [],
        product_options_attributes: [:id, :option_id, :name, :option_type, :_destroy, values: []]
      )
    end

    def attach_images
      Rails.logger.info "Attaching images: #{params[:images].inspect}"
      if params[:images].is_a?(Array)
        @product.images.attach(params[:images])
      else
        @product.images.attach(params[:images])
      end
      Rails.logger.info "Images attached. Count: #{@product.images.count}"
    end
  end
end


