class CreateCurrencyConversions < ActiveRecord::Migration[8.0]
  def change
    create_table :currency_conversions do |t|
      t.references :currency_rate, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :from_value, precision: 20, scale: 10, null: false
      t.decimal :to_value, precision: 20, scale: 10, null: false
      t.boolean :force_refresh, default: false

      t.timestamps
    end

    add_index :currency_conversions, [:user_id, :created_at]
  end
end 