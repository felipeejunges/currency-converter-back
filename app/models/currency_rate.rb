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