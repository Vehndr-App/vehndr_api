# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_18_192505) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "cart_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "cart_id", null: false
    t.string "product_id", null: false
    t.string "vendor_id", null: false
    t.integer "quantity", default: 1
    t.jsonb "selected_options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
    t.index ["selected_options"], name: "index_cart_items_on_selected_options", using: :gin
    t.index ["vendor_id"], name: "index_cart_items_on_vendor_id"
  end

  create_table "carts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_carts_on_session_id"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "event_coordinators", id: :string, force: :cascade do |t|
    t.string "name", null: false
    t.string "organization"
    t.text "bio"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_event_coordinators_on_name"
  end

  create_table "event_vendors", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "vendor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "vendor_id"], name: "index_event_vendors_on_event_id_and_vendor_id", unique: true
    t.index ["event_id"], name: "index_event_vendors_on_event_id"
    t.index ["vendor_id"], name: "index_event_vendors_on_vendor_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "location"
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.string "image"
    t.string "category"
    t.integer "attendees", default: 0, null: false
    t.string "status", default: "upcoming", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["start_date"], name: "index_events_on_start_date"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "order_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.string "product_id", null: false
    t.integer "quantity", null: false
    t.integer "price_cents", null: false
    t.jsonb "selected_options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "vendor_id", null: false
    t.integer "total_cents", null: false
    t.string "status", default: "pending"
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_orders_on_status"
    t.index ["stripe_checkout_session_id"], name: "index_orders_on_stripe_checkout_session_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.index ["vendor_id"], name: "index_orders_on_vendor_id"
  end

  create_table "product_options", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "product_id", null: false
    t.string "option_id", null: false
    t.string "name", null: false
    t.string "option_type", default: "select"
    t.string "values", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "option_id"], name: "index_product_options_on_product_id_and_option_id", unique: true
    t.index ["product_id"], name: "index_product_options_on_product_id"
  end

  create_table "products", id: :string, force: :cascade do |t|
    t.string "vendor_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "price", null: false
    t.string "image"
    t.boolean "is_service", default: false
    t.integer "duration"
    t.string "available_time_slots", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_service"], name: "index_products_on_is_service"
    t.index ["name"], name: "index_products_on_name"
    t.index ["vendor_id"], name: "index_products_on_vendor_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "role", default: "customer"
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "vendors", id: :string, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "hero_image"
    t.string "location"
    t.decimal "rating", precision: 2, scale: 1, default: "0.0"
    t.string "categories", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["categories"], name: "index_vendors_on_categories", using: :gin
    t.index ["name"], name: "index_vendors_on_name"
    t.index ["user_id"], name: "index_vendors_on_user_id"
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "cart_items", "vendors"
  add_foreign_key "carts", "users"
  add_foreign_key "event_vendors", "events"
  add_foreign_key "event_vendors", "vendors"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "vendors"
  add_foreign_key "product_options", "products"
  add_foreign_key "products", "vendors"
  add_foreign_key "vendors", "users"
end
