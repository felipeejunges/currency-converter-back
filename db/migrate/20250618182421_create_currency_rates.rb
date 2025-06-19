class CreateCurrencyRates < ActiveRecord::Migration[8.0]
  def change
    create_table :currency_rates do |t|
      t.references :from_currency, null: false, foreign_key: { to_table: :currencies }
      t.references :to_currency, null: false, foreign_key: { to_table: :currencies }
      t.decimal :rate, precision: 20, scale: 10, null: false
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    add_index :currency_rates, [:from_currency_id, :to_currency_id], unique: true, name: 'index_currency_rates_on_from_and_to_currency'
    add_index :currency_rates, :fetched_at
  end
end 