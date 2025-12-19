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

ActiveRecord::Schema[8.0].define(version: 2025_12_18_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.string "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.uuid "user_id"
    t.index ["name"], name: "index_event_coordinators_on_name"
    t.index ["user_id"], name: "index_event_coordinators_on_user_id"
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
    t.text "image"
    t.string "category"
    t.integer "attendees", default: 0, null: false
    t.string "status", default: "upcoming", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "coordinator_id"
    t.vector "embedding", limit: 1536
    t.index ["coordinator_id"], name: "index_events_on_coordinator_id"
    t.index ["start_date"], name: "index_events_on_start_date"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "order_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.string "product_id"
    t.integer "quantity", null: false
    t.integer "price_cents", null: false
    t.jsonb "selected_options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "product_name"
    t.boolean "is_custom", default: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "vendor_id", null: false
    t.integer "total_cents", null: false
    t.string "status", default: "pending"
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_charge_id"
    t.integer "application_fee_cents", default: 0
    t.decimal "platform_fee_percent", precision: 5, scale: 2
    t.string "payment_status", default: "pending"
    t.string "guest_email"
    t.string "guest_name"
    t.string "guest_phone"
    t.string "refund_status"
    t.integer "refund_amount_cents", default: 0
    t.datetime "refunded_at"
    t.string "stripe_refund_id"
    t.boolean "is_in_person", default: false
    t.string "payment_method"
    t.index ["is_in_person"], name: "index_orders_on_is_in_person"
    t.index ["payment_method"], name: "index_orders_on_payment_method"
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["refund_status"], name: "index_orders_on_refund_status"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["stripe_charge_id"], name: "index_orders_on_stripe_charge_id"
    t.index ["stripe_checkout_session_id"], name: "index_orders_on_stripe_checkout_session_id"
    t.index ["stripe_refund_id"], name: "index_orders_on_stripe_refund_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.index ["vendor_id"], name: "index_orders_on_vendor_id"
    t.check_constraint "user_id IS NOT NULL OR guest_email IS NOT NULL", name: "orders_must_have_user_or_guest"
  end

  create_table "password_reset_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_password_reset_tokens_on_token", unique: true
    t.index ["user_id", "expires_at"], name: "index_password_reset_tokens_on_user_id_and_expires_at"
    t.index ["user_id"], name: "index_password_reset_tokens_on_user_id"
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
    t.boolean "is_service", default: false
    t.integer "duration"
    t.string "available_time_slots", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding", limit: 1536
    t.string "booked_time_slots", default: [], array: true
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
    t.string "location"
    t.decimal "rating", precision: 2, scale: 1, default: "0.0"
    t.string "categories", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.vector "embedding", limit: 1536
    t.string "stripe_account_id"
    t.boolean "stripe_onboarding_completed", default: false
    t.boolean "stripe_charges_enabled", default: false
    t.boolean "stripe_payouts_enabled", default: false
    t.boolean "stripe_details_submitted", default: false
    t.datetime "stripe_connected_at"
    t.index ["categories"], name: "index_vendors_on_categories", using: :gin
    t.index ["name"], name: "index_vendors_on_name"
    t.index ["stripe_account_id"], name: "index_vendors_on_stripe_account_id"
    t.index ["stripe_charges_enabled"], name: "index_vendors_on_stripe_charges_enabled"
    t.index ["user_id"], name: "index_vendors_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "cart_items", "vendors"
  add_foreign_key "carts", "users"
  add_foreign_key "event_coordinators", "users"
  add_foreign_key "event_vendors", "events"
  add_foreign_key "event_vendors", "vendors"
  add_foreign_key "events", "event_coordinators", column: "coordinator_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "vendors"
  add_foreign_key "password_reset_tokens", "users"
  add_foreign_key "product_options", "products"
  add_foreign_key "products", "vendors"
  add_foreign_key "vendors", "users"
end
