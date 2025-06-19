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
#  index_currency_rates_on_fetched_at            (fetched_at)
#  index_currency_rates_on_from_and_to_currency  (from_currency_id,to_currency_id) UNIQUE
#  index_currency_rates_on_from_currency_id      (from_currency_id)
#  index_currency_rates_on_to_currency_id        (to_currency_id)
#
# Foreign Keys
#
#  fk_rails_...  (from_currency_id => currencies.id)
#  fk_rails_...  (to_currency_id => currencies.id)
#
class CurrencyRate < ApplicationRecord
  belongs_to :from_currency, class_name: 'Currency'
  belongs_to :to_currency, class_name: 'Currency'
  has_many :currency_conversions, dependent: :destroy

  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :fetched_at, presence: true
  validates :from_currency_id, uniqueness: { scope: :to_currency_id }

  scope :recent, -> { order(fetched_at: :desc) }
  scope :today, -> { where('fetched_at >= ?', Time.current.beginning_of_day) }

  def self.latest_for(from_currency, to_currency)
    where(from_currency: from_currency, to_currency: to_currency)
      .recent
      .first
  end

  def self.create_or_update_rate(from_currency, to_currency, rate)
    currency_rate = find_or_initialize_by(
      from_currency: from_currency,
      to_currency: to_currency
    )

    currency_rate.rate = rate
    currency_rate.fetched_at = Time.current
    currency_rate.save!
    currency_rate
  end

  def inverse_rate
    return nil if rate.zero?

    1.0 / rate
  end
end
