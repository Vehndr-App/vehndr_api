Rails.application.routes.draw do
  # Mount ActionCable
  mount ActionCable.server => '/cable'
  
  namespace :api do
    # Test endpoint for creating orders with broadcasts (development only)
    post 'test_orders', to: 'test_orders#create' if Rails.env.development?
    
    # Vendors
    resources :vendors, only: [:index, :show] do
      member do
        get 'products'
        get 'orders'
      end
    end

    # Products
    resources :products, only: [:index, :show]

    # Events
    resources :events, only: [:index, :show]

    # Cart
    resource :cart, controller: 'cart', only: [:show] do
      post 'items', action: :add_item
      patch 'items/:id', action: :update_item
      delete 'items/:id', action: :remove_item
      delete 'vendors/:vendor_id', action: :clear_vendor
      delete '/', action: :clear
    end

    # Checkout
    namespace :checkout do
      post 'sessions', action: :create_session
      get 'success', action: :success
      get 'cancel', action: :cancel
      post 'webhook', action: :webhook
    end

    # Auth
    namespace :auth do
      post 'login', action: :login
      post 'register', action: :register
      post 'logout', action: :logout
      get 'current_user', action: :current_user_info
    end

    # Event Coordinators
    resources :coordinators, controller: 'event_coordinators', only: [:index, :show]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
