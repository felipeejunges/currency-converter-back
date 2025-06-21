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

ActiveRecord::Schema[8.0].define(version: 2025_06_20_001533) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "currencies", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "symbol", null: false
    t.string "symbol_native", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_currencies_on_code", unique: true
  end

  create_table "currency_conversions", force: :cascade do |t|
    t.bigint "currency_rate_id", null: false
    t.bigint "user_id", null: false
    t.decimal "from_value", precision: 20, scale: 10, null: false
    t.decimal "to_value", precision: 20, scale: 10, null: false
    t.boolean "force_refresh", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_rate_id"], name: "index_currency_conversions_on_currency_rate_id"
    t.index ["user_id", "created_at"], name: "index_currency_conversions_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_currency_conversions_on_user_id"
  end

  create_table "currency_rates", force: :cascade do |t|
    t.bigint "from_currency_id", null: false
    t.bigint "to_currency_id", null: false
    t.decimal "rate", precision: 20, scale: 10, null: false
    t.datetime "fetched_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fetched_at"], name: "index_currency_rates_on_fetched_at"
    t.index ["from_currency_id"], name: "index_currency_rates_on_from_currency_id"
    t.index ["to_currency_id"], name: "index_currency_rates_on_to_currency_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "currency_conversions", "currency_rates"
  add_foreign_key "currency_conversions", "users"
  add_foreign_key "currency_rates", "currencies", column: "from_currency_id"
  add_foreign_key "currency_rates", "currencies", column: "to_currency_id"
end
