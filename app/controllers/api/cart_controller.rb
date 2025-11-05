module Api
  class CartController < BaseController
    before_action :set_cart_item, only: [:update_item, :remove_item]

    # GET /api/cart
    def show
      cart_items = current_cart.cart_items
                               .includes(product: :product_options, vendor: [])
                               .order(created_at: :desc)
      
      render json: format_cart_response(cart_items)
    end

    # POST /api/cart/items
    def add_item
      product = Product.find(params[:product_id])
      
      cart_item = current_cart.cart_items.find_or_initialize_by(
        product: product,
        selected_options: params[:selected_options] || {}
      )

      if cart_item.persisted?
        cart_item.quantity += (params[:quantity] || 1).to_i
      else
        cart_item.quantity = (params[:quantity] || 1).to_i
      end

      if cart_item.save
        render json: format_cart_response(current_cart.cart_items.includes(product: :product_options, vendor: []))
      else
        render json: { 
          error: 'Failed to add item to cart',
          errors: cart_item.errors.full_messages 
        }, status: :unprocessable_entity
      end
    end

    # PATCH /api/cart/items/:id
    def update_item
      if @cart_item.update(cart_item_params)
        render json: format_cart_response(current_cart.cart_items.includes(product: :product_options, vendor: []))
      else
        render json: { 
          error: 'Failed to update cart item',
          errors: @cart_item.errors.full_messages 
        }, status: :unprocessable_entity
      end
    end

    # DELETE /api/cart/items/:id
    def remove_item
      @cart_item.destroy
      render json: format_cart_response(current_cart.cart_items.includes(product: :product_options, vendor: []))
    end

    # DELETE /api/cart/vendors/:vendor_id
    def clear_vendor
      current_cart.clear_vendor_items(params[:vendor_id])
      render json: format_cart_response(current_cart.cart_items.includes(product: :product_options, vendor: []))
    end

    # DELETE /api/cart
    def clear
      current_cart.cart_items.destroy_all
      render json: { vendorCarts: {} }
    end

    private

    def set_cart_item
      @cart_item = current_cart.cart_items.find(params[:id])
    end

    def cart_item_params
      params.permit(:quantity, selected_options: {})
    end

    def format_cart_response(cart_items)
      vendor_carts = {}
      
      cart_items.group_by(&:vendor_id).each do |vendor_id, items|
        vendor_carts[vendor_id] = items.map do |item|
          {
            id: item.id,
            productId: item.product_id,
            vendorId: item.vendor_id,
            name: item.product.name,
            image: item.product.image,
            price: item.product.price,
            quantity: item.quantity,
            options: item.selected_options,
            isService: item.product.is_service,
            duration: item.product.duration
          }
        end
      end

      { vendorCarts: vendor_carts }
    end
  end
end


