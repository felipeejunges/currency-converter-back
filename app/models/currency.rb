class Currency < ApplicationRecord
  has_many :from_currency_rates, class_name: 'CurrencyRate', foreign_key: 'from_currency_id', dependent: :destroy
  has_many :to_currency_rates, class_name: 'CurrencyRate', foreign_key: 'to_currency_id', dependent: :destroy

  validates :code, presence: true, uniqueness: true, length: { is: 3 }
  validates :name, presence: true
  validates :symbol, presence: true
  validates :symbol_native, presence: true

  scope :supported, -> { where(code: %w[BRL USD EUR JPY]) }

  def self.find_by_code(code)
    find_by(code: code.upcase)
  end

  def supported?
    %w[BRL USD EUR JPY].include?(code)
  end

  def latest_rate_to(target_currency)
    to_currency_rates.where(to_currency: target_currency).order(fetched_at: :desc).first
  end

  def latest_rate_from(source_currency)
    from_currency_rates.where(from_currency: source_currency).order(fetched_at: :desc).first
  end
end 