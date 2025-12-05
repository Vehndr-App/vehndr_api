module Api
  class TestOrdersController < BaseController
    # POST /api/test_orders
    def create
      user = User.find_by(email: 'customer@example.com')
      vendor = Vendor.find_by(id: 'vendor_artisan_1')
      
      order = Order.create!(
        user: user,
        vendor: vendor,
        total_cents: rand(5000..15000),
        status: ['pending', 'confirmed'].sample
      )
      
      # Broadcast via ActionCable
      VendorOrdersChannel.broadcast_to(
        vendor,
        {
          event: 'order.created',
          order: {
            id: order.id,
            total_cents: order.total_cents,
            status: order.status,
            created_at: order.created_at
          }
        }
      )
      
      render json: { 
        message: 'Order created and broadcast sent',
        order: {
          id: order.id,
          total_cents: order.total_cents,
          status: order.status
        }
      }
    end
  end
end


















