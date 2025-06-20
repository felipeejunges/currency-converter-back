# frozen_string_literal: true

# == Schema Information
#
# Table name: currencies
#
#  id            :bigint           not null, primary key
#  code          :string           not null
#  name          :string           not null
#  symbol        :string           not null
#  symbol_native :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_currencies_on_code  (code) UNIQUE
#
FactoryBot.define do # rubocop:disable Metrics/BlockLength
  factory :currency do # rubocop:disable Metrics/BlockLength
    sequence(:code) { |n| "CUR#{n}" }
    sequence(:name) { |n| "Currency #{n}" }
    symbol { '$' }
    symbol_native { '$' }

    trait :usd do
      code { 'USD' }
      name { 'US Dollar' }
      symbol { '$' }
      symbol_native { '$' }
    end

    trait :brl do
      code { 'BRL' }
      name { 'Brazilian Real' }
      symbol { 'R$' }
      symbol_native { 'R$' }
    end

    trait :eur do
      code { 'EUR' }
      name { 'Euro' }
      symbol { '€' }
      symbol_native { '€' }
    end

    trait :jpy do
      code { 'JPY' }
      name { 'Japanese Yen' }
      symbol { '¥' }
      symbol_native { '¥' }
    end
  end
end
