# frozen_string_literal: true

module Currency
  class ConversionService
    attr_reader :user, :from_currency, :to_currency, :from_value, :force_refresh

    def initialize(user:, from_currency:, to_currency:, from_value:, force_refresh: false)
      @user = user
      @from_currency = from_currency
      @to_currency = to_currency
      @from_value = from_value.to_f
      @force_refresh = force_refresh
    end

    def call
      validate_currencies!
      validate_from_value!

      currency_rate = fetch_currency_rate
      to_value = calculate_conversion(from_value, currency_rate.rate)

      create_conversion_record(currency_rate, to_value)
    rescue StandardError => e
      Rails.logger.error("Currency conversion failed: #{e.message}")
      raise ConversionError, e.message
    end

    private

    def validate_currencies!
      return if from_currency.present? && to_currency.present?

      raise ConversionError, 'Both from_currency and to_currency are required'
    end

    def validate_from_value!
      return if from_value.positive?

      raise ConversionError, 'from_value must be greater than 0'
    end

    def fetch_currency_rate
      if force_refresh
        fetch_live_rate
      else
        fetch_cached_rate || fetch_live_rate
      end
    end

    def fetch_cached_rate
      CurrencyRate.latest_for(from_currency, to_currency)
    end

    def fetch_live_rate
      Currency::RateFetcherService.new(
        from_currency: from_currency,
        to_currency: to_currency
      ).call
    end

    def calculate_conversion(value, rate)
      (value * rate).round(2)
    end

    def create_conversion_record(currency_rate, to_value)
      Currency::Conversion.create!(
        user: user,
        currency_rate: currency_rate,
        from_value: from_value,
        to_value: to_value,
        force_refresh: force_refresh
      )
    end

    class ConversionError < StandardError; end
  end
end
