# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Clear existing data
puts "Clearing existing data..."
OrderItem.destroy_all
Order.destroy_all
CartItem.destroy_all
Cart.destroy_all
ProductOption.destroy_all
Product.destroy_all
EventVendor.destroy_all
Event.destroy_all
Vendor.destroy_all
EventCoordinator.destroy_all
User.destroy_all

# Create demo users
puts "Creating users..."
customer = User.create!(
  email: 'customer@example.com',
  password: 'password123',
  name: 'Demo Customer',
  role: 'customer'
)

vendor_user = User.create!(
  email: 'vendor@example.com',
  password: 'password123',
  name: 'Demo Vendor',
  role: 'vendor'
)

coordinator_user = User.create!(
  email: 'coordinator@example.com',
  password: 'password123',
  name: 'Demo Coordinator',
  role: 'coordinator'
)

# Create vendors
puts "Creating vendors..."

artisan_alley = Vendor.create!(
  id: 'vendor_artisan_1',
  user: vendor_user,
  name: 'Artisan Alley',
  description: 'Handcrafted jewelry, pottery, and unique art pieces from local artisans',
  location: 'Austin, TX',
  rating: 4.8,
  categories: ['Clothing & Accessories', 'Other'],
  stripe_account_id: 'acct_test_artisan_1',
  stripe_charges_enabled: true,
  stripe_payouts_enabled: true,
  stripe_onboarding_completed: true,
  stripe_details_submitted: true,
  stripe_connected_at: Time.current
)

foodie_favorites = Vendor.create!(
  id: 'vendor_foodie_1',
  name: 'Foodie Favorites',
  description: 'Gourmet snacks, artisanal foods, and specialty treats',
  location: 'Portland, OR',
  rating: 4.9,
  categories: ['Food & Beverage'],
  stripe_account_id: 'acct_test_foodie_1',
  stripe_charges_enabled: true,
  stripe_payouts_enabled: true,
  stripe_onboarding_completed: true,
  stripe_details_submitted: true,
  stripe_connected_at: Time.current
)

tech_trends = Vendor.create!(
  id: 'vendor_tech_1',
  name: 'Tech Trends',
  description: 'Latest gadgets, accessories, and innovative tech products',
  location: 'San Francisco, CA',
  rating: 4.7,
  categories: ['Clothing & Accessories', 'Other'],
  stripe_account_id: 'acct_test_tech_1',
  stripe_charges_enabled: true,
  stripe_payouts_enabled: true,
  stripe_onboarding_completed: true,
  stripe_details_submitted: true,
  stripe_connected_at: Time.current
)

wellness_works = Vendor.create!(
  id: 'vendor_wellness_1',
  name: 'Wellness Works',
  description: 'Health, wellness, and relaxation services for mind and body',
  location: 'Los Angeles, CA',
  rating: 4.9,
  categories: ['Health & Wellness', 'Workshops'],
  stripe_account_id: 'acct_test_wellness_1',
  stripe_charges_enabled: true,
  stripe_payouts_enabled: true,
  stripe_onboarding_completed: true,
  stripe_details_submitted: true,
  stripe_connected_at: Time.current
)

style_street = Vendor.create!(
  id: 'vendor_style_1',
  name: 'Style Street',
  description: 'Trendy apparel, accessories, and fashion-forward designs',
  location: 'New York, NY',
  rating: 4.6,
  categories: ['Clothing & Accessories', 'Beauty'],
  stripe_account_id: 'acct_test_style_1',
  stripe_charges_enabled: true,
  stripe_payouts_enabled: true,
  stripe_onboarding_completed: true,
  stripe_details_submitted: true,
  stripe_connected_at: Time.current
)

# Create events and memberships
puts "Creating events..."

spring_market = Event.create!(
  name: 'Spring Makers Market',
  description: 'Local makers and artisans showcase unique, handcrafted goods.',
  location: 'Austin, TX',
  start_date: Time.zone.parse('2026-03-21 10:00'),
  end_date: Time.zone.parse('2026-03-21 18:00'),
  category: 'Market',
  attendees: 2500,
  status: 'upcoming'
)

tech_expo = Event.create!(
  name: 'Tech Expo 2026',
  description: 'Latest consumer electronics and gadgets on display.',
  location: 'San Francisco, CA',
  start_date: Time.zone.parse('2026-05-04 09:00'),
  end_date: Time.zone.parse('2026-05-06 17:00'),
  category: 'Expo',
  attendees: 18000,
  status: 'upcoming'
)

wellness_fair = Event.create!(
  name: 'Wellness & Mindfulness Fair',
  description: 'Health, wellness, yoga, and relaxation experiences.',
  location: 'Los Angeles, CA',
  start_date: Time.zone.parse('2026-02-12 10:00'),
  end_date: Time.zone.parse('2026-02-12 16:00'),
  category: 'Wellness',
  attendees: 3200,
  status: 'past'
)

food_fest = Event.create!(
  name: 'Gourmet Street Food Fest',
  description: 'Artisan snacks, specialty treats, and street food favorites.',
  location: 'Portland, OR',
  start_date: Time.zone.parse('2026-06-15 11:00'),
  end_date: Time.zone.parse('2026-06-15 20:00'),
  category: 'Food',
  attendees: 9200,
  status: 'upcoming'
)

holiday_bazaar = Event.create!(
  name: 'Holiday Bazaar',
  description: 'Seasonal crafts, gifts, and apparel from local sellers.',
  location: 'New York, NY',
  start_date: Time.zone.parse('2025-12-10 10:00'),
  end_date: Time.zone.parse('2025-12-12 19:00'),
  category: 'Market',
  attendees: 12000,
  status: 'active'
)

# Memberships
spring_market.vendors << [artisan_alley, style_street]
tech_expo.vendors << [tech_trends]
wellness_fair.vendors << [wellness_works]
food_fest.vendors << [foodie_favorites, artisan_alley]
holiday_bazaar.vendors << [artisan_alley, foodie_favorites, style_street]

# Create products for Artisan Alley
puts "Creating products for Artisan Alley..."

handmade_necklace = Product.create!(
  id: 'prod_artisan_necklace_1',
  vendor: artisan_alley,
  name: 'Handmade Silver Necklace',
  description: 'Beautiful handcrafted silver necklace with turquoise stone pendant',
  price: 8500, # $85.00
  is_service: false
)

ProductOption.create!([
  {
    product: handmade_necklace,
    option_id: 'length',
    name: 'Chain Length',
    option_type: 'select',
    values: ['16 inches', '18 inches', '20 inches', '24 inches']
  }
])

ceramic_bowl = Product.create!(
  id: 'prod_artisan_bowl_1',
  vendor: artisan_alley,
  name: 'Hand-thrown Ceramic Bowl',
  description: 'Unique ceramic bowl perfect for serving or decoration',
  price: 4500, # $45.00
  is_service: false
)

ProductOption.create!([
  {
    product: ceramic_bowl,
    option_id: 'size',
    name: 'Size',
    option_type: 'select',
    values: ['Small (6")', 'Medium (8")', 'Large (10")']
  },
  {
    product: ceramic_bowl,
    option_id: 'color',
    name: 'Glaze Color',
    option_type: 'select',
    values: ['Ocean Blue', 'Forest Green', 'Sunset Orange', 'Natural Clay']
  }
])

# Create products for Foodie Favorites
puts "Creating products for Foodie Favorites..."

gourmet_chocolate = Product.create!(
  id: 'prod_foodie_chocolate_1',
  vendor: foodie_favorites,
  name: 'Artisan Chocolate Box',
  description: 'Assorted handmade chocolates with unique flavor combinations',
  price: 3500, # $35.00
  is_service: false
)

ProductOption.create!([
  {
    product: gourmet_chocolate,
    option_id: 'size',
    name: 'Box Size',
    option_type: 'select',
    values: ['6 pieces', '12 pieces', '24 pieces']
  },
  {
    product: gourmet_chocolate,
    option_id: 'type',
    name: 'Chocolate Type',
    option_type: 'select',
    values: ['Dark', 'Milk', 'Mixed', 'White']
  }
])

hot_sauce_set = Product.create!(
  id: 'prod_foodie_sauce_1',
  vendor: foodie_favorites,
  name: 'Craft Hot Sauce Trio',
  description: 'Three unique hot sauces ranging from mild to extra spicy',
  price: 2800, # $28.00
  is_service: false
)

ProductOption.create!([
  {
    product: hot_sauce_set,
    option_id: 'heat',
    name: 'Heat Level Set',
    option_type: 'select',
    values: ['Mild Collection', 'Medium Collection', 'Hot Collection', 'Variety Pack']
  }
])

# Create products for Tech Trends
puts "Creating products for Tech Trends..."

wireless_earbuds = Product.create!(
  id: 'prod_tech_earbuds_1',
  vendor: tech_trends,
  name: 'Premium Wireless Earbuds',
  description: 'High-quality wireless earbuds with noise cancellation',
  price: 12900, # $129.00
  is_service: false
)

ProductOption.create!([
  {
    product: wireless_earbuds,
    option_id: 'color',
    name: 'Color',
    option_type: 'select',
    values: ['Midnight Black', 'Pearl White', 'Rose Gold', 'Space Gray']
  }
])

phone_case = Product.create!(
  id: 'prod_tech_case_1',
  vendor: tech_trends,
  name: 'Custom Phone Case',
  description: 'Durable phone case with customizable design options',
  price: 3500, # $35.00
  is_service: false
)

ProductOption.create!([
  {
    product: phone_case,
    option_id: 'model',
    name: 'Phone Model',
    option_type: 'select',
    values: ['iPhone 15 Pro', 'iPhone 15', 'iPhone 14', 'Samsung S24', 'Pixel 8']
  },
  {
    product: phone_case,
    option_id: 'style',
    name: 'Case Style',
    option_type: 'select',
    values: ['Clear', 'Matte Black', 'Leather', 'Silicone']
  }
])

# Create services for Wellness Works
puts "Creating services for Wellness Works..."

chair_massage = Product.create!(
  id: 'service_massage_1',
  vendor: wellness_works,
  name: 'Chair Massage Session',
  description: 'Relaxing chair massage focusing on neck, shoulders, and back',
  price: 5000, # $50.00
  is_service: true,
  duration: 30,
  available_time_slots: ['9:00 AM', '9:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', 
                         '2:00 PM', '2:30 PM', '3:00 PM', '3:30 PM', '4:00 PM']
)

ProductOption.create!([
  {
    product: chair_massage,
    option_id: 'pressure',
    name: 'Pressure Preference',
    option_type: 'select',
    values: ['Light', 'Medium', 'Firm', 'Extra Firm']
  },
  {
    product: chair_massage,
    option_id: 'focus',
    name: 'Focus Area',
    option_type: 'select',
    values: ['Full Upper Body', 'Neck & Shoulders', 'Back Only', 'Arms & Hands']
  }
])

yoga_session = Product.create!(
  id: 'service_yoga_1',
  vendor: wellness_works,
  name: 'Private Yoga Session',
  description: 'One-on-one yoga instruction tailored to your level',
  price: 7500, # $75.00
  is_service: true,
  duration: 60,
  available_time_slots: ['7:00 AM', '8:00 AM', '9:00 AM', '10:00 AM', 
                         '4:00 PM', '5:00 PM', '6:00 PM']
)

ProductOption.create!([
  {
    product: yoga_session,
    option_id: 'level',
    name: 'Experience Level',
    option_type: 'select',
    values: ['Beginner', 'Intermediate', 'Advanced', 'Mixed Level']
  },
  {
    product: yoga_session,
    option_id: 'style',
    name: 'Yoga Style',
    option_type: 'select',
    values: ['Hatha', 'Vinyasa', 'Yin', 'Restorative']
  }
])

meditation = Product.create!(
  id: 'service_meditation_1',
  vendor: wellness_works,
  name: 'Guided Meditation',
  description: 'Peaceful guided meditation session for stress relief',
  price: 3500, # $35.00
  is_service: true,
  duration: 45,
  available_time_slots: ['8:00 AM', '10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM']
)

ProductOption.create!([
  {
    product: meditation,
    option_id: 'type',
    name: 'Meditation Type',
    option_type: 'select',
    values: ['Mindfulness', 'Breathing', 'Body Scan', 'Visualization']
  }
])

# Create products for Style Street
puts "Creating products for Style Street..."

graphic_tee = Product.create!(
  id: 'prod_style_tee_1',
  vendor: style_street,
  name: 'Vintage Graphic T-Shirt',
  description: 'Comfortable cotton tee with unique vintage-inspired designs',
  price: 3200, # $32.00
  is_service: false
)

ProductOption.create!([
  {
    product: graphic_tee,
    option_id: 'size',
    name: 'Size',
    option_type: 'select',
    values: ['XS', 'S', 'M', 'L', 'XL', 'XXL']
  },
  {
    product: graphic_tee,
    option_id: 'color',
    name: 'Color',
    option_type: 'select',
    values: ['Black', 'White', 'Navy', 'Heather Gray', 'Vintage Red']
  }
])

canvas_tote = Product.create!(
  id: 'prod_style_tote_1',
  vendor: style_street,
  name: 'Canvas Tote Bag',
  description: 'Durable canvas tote perfect for shopping or daily use',
  price: 2800, # $28.00
  is_service: false
)

ProductOption.create!([
  {
    product: canvas_tote,
    option_id: 'color',
    name: 'Color',
    option_type: 'select',
    values: ['Natural', 'Black', 'Navy', 'Forest Green', 'Burgundy']
  },
  {
    product: canvas_tote,
    option_id: 'personalization',
    name: 'Add Monogram',
    option_type: 'select',
    values: ['No Monogram', 'Add Initials (+$5)', 'Add Name (+$8)']
  }
])

sunglasses = Product.create!(
  id: 'prod_style_sunglasses_1',
  vendor: style_street,
  name: 'Polarized Sunglasses',
  description: 'Stylish polarized sunglasses with UV protection',
  price: 4500, # $45.00
  is_service: false
)

ProductOption.create!([
  {
    product: sunglasses,
    option_id: 'style',
    name: 'Frame Style',
    option_type: 'select',
    values: ['Aviator', 'Wayfarer', 'Round', 'Cat Eye', 'Sport']
  },
  {
    product: sunglasses,
    option_id: 'lens',
    name: 'Lens Color',
    option_type: 'select',
    values: ['Black', 'Brown', 'Blue Mirror', 'Green', 'Gray']
  }
])

# Create Event Coordinators
puts "Creating event coordinators..."

EventCoordinator.create!([
  {
    id: 'coord_sarah_1',
    name: 'Sarah Johnson',
    organization: 'City Events Management',
    bio: 'With over 10 years of experience organizing large-scale events, Sarah specializes in vendor coordination and logistics.',
    avatar: '/placeholder.svg?height=200&width=200&text=SJ'
  },
  {
    id: 'coord_mike_1',
    name: 'Mike Chen',
    organization: 'Festival Productions Inc.',
    bio: 'Mike brings creative vision and technical expertise to every event, ensuring memorable experiences for all attendees.',
    avatar: '/placeholder.svg?height=200&width=200&text=MC'
  },
  {
    id: 'coord_emily_1',
    name: 'Emily Rodriguez',
    organization: 'Community Connect',
    bio: 'Emily focuses on bringing communities together through thoughtfully curated local events and marketplaces.',
    avatar: '/placeholder.svg?height=200&width=200&text=ER'
  },
  {
    id: 'coord_james_1',
    name: 'James Thompson',
    organization: 'Premier Event Solutions',
    bio: 'James specializes in high-end corporate events and exclusive vendor showcases with attention to every detail.',
    avatar: '/placeholder.svg?height=200&width=200&text=JT'
  }
])

# Create some sample carts and orders for demonstration
puts "Creating sample cart items and orders..."

# Create a cart for the demo customer
customer_cart = customer.carts.create!

# Add some items to the cart
CartItem.create!([
  {
    cart: customer_cart,
    product: handmade_necklace,
    vendor: artisan_alley,
    quantity: 1,
    selected_options: { 'length' => '18 inches' }
  },
  {
    cart: customer_cart,
    product: gourmet_chocolate,
    vendor: foodie_favorites,
    quantity: 2,
    selected_options: { 'size' => '12 pieces', 'type' => 'Dark' }
  },
  {
    cart: customer_cart,
    product: chair_massage,
    vendor: wellness_works,
    quantity: 1,
    selected_options: { 
      'timeSlot' => '10:00 AM',
      'pressure' => 'Medium',
      'focus' => 'Full Upper Body'
    }
  }
])

# Create sample orders for Artisan Alley (linked to Demo Vendor user)
puts "Creating sample orders for Artisan Alley..."

# Completed order from yesterday
order1 = Order.create!(
  user: customer,
  vendor: artisan_alley,
  total_cents: 13000, # $130.00
  status: 'confirmed',
  created_at: 1.day.ago
)

OrderItem.create!(
  order: order1,
  product: handmade_necklace,
  quantity: 1,
  price_cents: 8500,
  selected_options: { 'length' => '20 inches' }
)

OrderItem.create!(
  order: order1,
  product: ceramic_bowl,
  quantity: 1,
  price_cents: 4500,
  selected_options: { 'size' => 'Small (6")', 'color' => 'Ocean Blue' }
)

# Pending order from today
order2 = Order.create!(
  user: customer,
  vendor: artisan_alley,
  total_cents: 4500, # $45.00
  status: 'confirmed',
  created_at: 2.hours.ago
)

OrderItem.create!(
  order: order2,
  product: ceramic_bowl,
  quantity: 1,
  price_cents: 4500,
  selected_options: { 'size' => 'Medium (8")', 'color' => 'Natural Clay' }
)

puts "✅ Database seeded successfully!"
puts "📊 Created:"
puts "   - #{User.count} users"
puts "   - #{Vendor.count} vendors"
puts "   - #{Product.count} products (#{Product.products_only.count} products, #{Product.services_only.count} services)"
puts "   - #{ProductOption.count} product options"
puts "   - #{Event.count} events with #{EventVendor.count} vendor memberships"
puts "   - #{EventCoordinator.count} event coordinators"
puts "   - #{Cart.count} carts with #{CartItem.count} items"
puts ""
puts "🔐 Test Accounts:"
puts "   Customer: customer@example.com / password123"
puts "   Vendor: vendor@example.com / password123"
puts "   Coordinator: coordinator@example.com / password123"

# Optional: Seed demo events tied to vendors (uncomment to use)
#
# vendor_demo = Vendor.find_by(name: "Artisan Alley")
# vendor_food = Vendor.find_by(name: "Foodie Favorites")
# if vendor_demo && vendor_food
#   coachella = Event.create!(
#     name: "Coachella 2026",
#     description: "Music and Arts Festival in the desert",
#     location: "Indio, CA",
#     start_date: Time.zone.parse("2026-04-10"),
#     end_date: Time.zone.parse("2026-04-12"),
#     image: nil,
#     category: "Music Festival",
#     attendees: 125_000,
#     status: "upcoming"
#   )
#   coachella.vendors << [vendor_demo, vendor_food]
#   puts "   - Seeded demo event: #{coachella.name} with vendors"
# end