# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create supported currencies
currencies_data = [
  {
    code: 'BRL',
    name: 'Brazilian Real',
    symbol: 'R$',
    symbol_native: 'R$'
  },
  {
    code: 'USD',
    name: 'US Dollar',
    symbol: '$',
    symbol_native: '$'
  },
  {
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    symbol_native: '€'
  },
  {
    code: 'JPY',
    name: 'Japanese Yen',
    symbol: '¥',
    symbol_native: '¥'
  }
]

currencies_data.each do |currency_data|
  Currency.find_or_create_by!(code: currency_data[:code]) do |currency|
    currency.name = currency_data[:name]
    currency.symbol = currency_data[:symbol]
    currency.symbol_native = currency_data[:symbol_native]
  end
end

puts "Created #{Currency.count} currencies"
