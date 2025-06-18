module Currency
  class Conversion < ApplicationRecord
    self.table_name = 'currency_conversions'
    
    belongs_to :currency_rate
    belongs_to :user
    delegate :from_currency, :to_currency, to: :currency_rate

    validates :from_value, presence: true, numericality: { greater_than: 0 }
    validates :to_value, presence: true, numericality: { greater_than: 0 }
    validates :currency_rate, presence: true
    validates :user, presence: true

    scope :for_user, ->(user) { where(user: user) }
    scope :recent, -> { order(created_at: :desc) }

    before_create :log_conversion

    def rate
      currency_rate.rate
    end

    def from_currency_code
      from_currency.code
    end

    def to_currency_code
      to_currency.code
    end

    def timestamp
      created_at
    end

    private

    def log_conversion
      Rails.logger.info(
        "Currency conversion: #{from_value} #{from_currency_code} -> #{to_value} #{to_currency_code} " \
        "(Rate: #{rate}, User: #{user_id}, Force refresh: #{force_refresh})"
      )
    end
  end
end 