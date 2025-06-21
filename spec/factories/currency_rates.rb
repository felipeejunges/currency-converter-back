# frozen_string_literal: true

# == Schema Information
#
# Table name: currency_rates
#
#  id               :bigint           not null, primary key
#  fetched_at       :datetime         not null
#  rate             :decimal(20, 10)  not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  from_currency_id :bigint           not null
#  to_currency_id   :bigint           not null
#
# Indexes
#
#  index_currency_rates_on_fetched_at        (fetched_at)
#  index_currency_rates_on_from_currency_id  (from_currency_id)
#  index_currency_rates_on_to_currency_id    (to_currency_id)
#
# Foreign Keys
#
#  fk_rails_...  (from_currency_id => currencies.id)
#  fk_rails_...  (to_currency_id => currencies.id)
#
FactoryBot.define do
  factory :currency_rate do
    association :from_currency, factory: %i[currency usd]
    association :to_currency, factory: %i[currency brl]
    rate { 5.25 }
    fetched_at { Time.current }

    trait :different_currencies do
      association :from_currency, factory: %i[currency eur]
      association :to_currency, factory: %i[currency jpy]
      rate { 150.0 }
    end

    trait :third_combination do
      association :from_currency, factory: %i[currency brl]
      association :to_currency, factory: %i[currency usd]
      rate { 0.19 }
    end

    trait :fourth_combination do
      association :from_currency, factory: %i[currency jpy]
      association :to_currency, factory: %i[currency eur]
      rate { 0.0067 }
    end
  end
end
