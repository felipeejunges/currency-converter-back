# frozen_string_literal: true

module Currencies
  class RateFetcherService
    include HTTParty

    base_uri 'https://api.currencyapi.com/v3'

    attr_reader :from_currency

    def initialize(from_currency:)
      @from_currency = from_currency
    end

    def call
      response = fetch_rates_from_api
      parse_and_save_rates(response)
    rescue StandardError => e
      Rails.logger.error("Failed to fetch currency rates: #{e.message}")
      raise RateFetchError, "Failed to fetch rates: #{e.message}"
    end

    private

    def fetch_rates_from_api
      target_currencies = Currency.supported.where.not(code: from_currency.code).pluck(:code)
      currencies = target_currencies.join(',')

      response = latest(currencies)

      raise RateFetchError, "API request failed with status #{response.code}" unless response.success?

      response.parsed_response
    end

    def latest(currencies)
      api_key = ENV['CURRENCY_API_KEY']
      raise RateFetchError, 'Currency API key not configured' unless api_key

      self.class.get('/latest', {
                        query: {
                          apikey: api_key,
                          currencies: currencies,
                          base_currency: from_currency.code
                        },
                        timeout: 10
                      })
    end

    def parse_and_save_rates(response_data)
      data = response_data['data']
      raise RateFetchError, 'Invalid API response format' unless data

      data.each do |currency_code, currency_data|
        next if currency_code == from_currency.code

        rate = currency_data['value'].to_f
        raise RateFetchError, "Invalid rate value for #{currency_code}" unless rate.positive?

        to_currency = Currency.find_by_code(currency_code)
        next unless to_currency

        CurrencyRate.create!(
          from_currency: from_currency,
          to_currency: to_currency,
          rate: rate,
          fetched_at: Time.current
        )
      end
    end

    class RateFetchError < StandardError; end
  end
end
