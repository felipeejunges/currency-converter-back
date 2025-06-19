# frozen_string_literal: true

# == Schema Information
#
# Table name: currency_conversions
#
#  id               :bigint           not null, primary key
#  force_refresh    :boolean          default(FALSE)
#  from_value       :decimal(20, 10)  not null
#  to_value         :decimal(20, 10)  not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  currency_rate_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_currency_conversions_on_currency_rate_id        (currency_rate_id)
#  index_currency_conversions_on_user_id                 (user_id)
#  index_currency_conversions_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (currency_rate_id => currency_rates.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :currency_conversion, class: 'Currency::Conversion' do
    association :currency_rate
    association :user
    from_value { 100.0 }
    to_value { 525.0 }
    force_refresh { false }

    trait :different_currencies do
      association :currency_rate, factory: %i[currency_rate different_currencies]
      from_value { 50.0 }
      to_value { 7500.0 }
    end

    trait :third_combination do
      association :currency_rate, factory: %i[currency_rate third_combination]
      from_value { 200.0 }
      to_value { 38.0 }
    end
  end
end
