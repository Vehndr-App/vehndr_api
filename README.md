# Vehndr API - Rails Backend for Vendor Marketplace

A comprehensive Rails API backend for a vendor marketplace application with support for products, services, shopping cart, and Stripe checkout integration.

## Features

- 🛍️ **Multi-vendor marketplace** with products and services
- 🛒 **Shopping cart** with session-based and user-based persistence  
- 💳 **Stripe integration** for payment processing
- 🔐 **JWT authentication** for secure API access
- 📅 **Service booking** with time slot management
- 👥 **Multiple user roles** (customer, vendor, coordinator)
- 🔄 **CamelCase JSON** responses for frontend compatibility

## Tech Stack

- Ruby on Rails 8.0.2
- PostgreSQL
- JWT for authentication
- Stripe for payments
- ActiveModel Serializers for JSON formatting
- Rack CORS for cross-origin requests

## Prerequisites

- Ruby 3.2+ 
- PostgreSQL 14+
- Node.js (for Rails asset pipeline)
- Stripe account (for payment processing)

## Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd vehndr_api
```

2. **Install dependencies**
```bash
bundle install
```

3. **Setup database**
```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed with sample data
rails db:seed
```

4. **Configure credentials**
```bash
# Edit credentials
EDITOR="code --wait" rails credentials:edit

# Add your Stripe keys:
stripe:
  secret_key: sk_test_your_stripe_secret_key
  webhook_secret: whsec_your_webhook_secret
```

5. **Start the server**
```bash
rails server
```

The API will be available at `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login  
- `POST /api/auth/logout` - User logout
- `GET /api/auth/current_user` - Get current user

### Vendors
- `GET /api/vendors` - List all vendors
- `GET /api/vendors/:id` - Get vendor details
- `GET /api/vendors/:id/products` - Get vendor's products

### Products
- `GET /api/products` - List all products
- `GET /api/products/:id` - Get product details

### Shopping Cart
- `GET /api/cart` - Get current cart
- `POST /api/cart/items` - Add item to cart
- `PATCH /api/cart/items/:id` - Update cart item
- `DELETE /api/cart/items/:id` - Remove item from cart
- `DELETE /api/cart/vendors/:vendor_id` - Clear vendor items
- `DELETE /api/cart` - Clear entire cart

### Checkout
- `POST /api/checkout/sessions` - Create Stripe checkout session
- `GET /api/checkout/success` - Handle successful payment
- `GET /api/checkout/cancel` - Handle cancelled payment

### Event Coordinators
- `GET /api/coordinators` - List coordinators
- `GET /api/coordinators/:id` - Get coordinator details

## Test Accounts

After running seeds, you can use these test accounts:

- **Customer**: customer@example.com / password123
- **Vendor**: vendor@example.com / password123  
- **Coordinator**: coordinator@example.com / password123

## Data Models

### Core Models
- **Vendors** - Marketplace vendors with products/services
- **Products** - Both physical products and bookable services
- **ProductOptions** - Customizable options for products
- **Users** - System users with different roles
- **Carts** - Shopping carts (session or user-based)
- **CartItems** - Items in shopping carts
- **Orders** - Completed purchases
- **OrderItems** - Items within orders
- **EventCoordinators** - Event management profiles

## Frontend Integration

The API is designed to work with a Next.js frontend and includes:

- CORS configuration for localhost:3000 (development)
- CamelCase JSON keys for JavaScript compatibility
- Vendor-grouped cart structure
- Service booking with time slots
- Session-based guest checkout

## Environment Variables

For production, set these environment variables:

```bash
DATABASE_URL=postgres://user:pass@host/database
STRIPE_SECRET_KEY=sk_live_your_stripe_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
SECRET_KEY_BASE=your_secret_key_base
```

## Development

### Running tests
```bash
rails test
```

### Database console
```bash
rails dbconsole
```

### Rails console
```bash
rails console
```

### Reset database
```bash
rails db:reset
```

## Deployment

The application includes Docker support via Kamal for easy deployment:

```bash
# Deploy with Kamal
kamal deploy
```

## License

This project is private and proprietary.

## Support

For issues or questions, please contact the development team.