# frozen_string_literal: true

module Currency
  class RateFetcherService
    include HTTParty

    base_uri 'https://api.currencyapi.com/v3'

    attr_reader :from_currency, :to_currency

    def initialize(from_currency:, to_currency:)
      @from_currency = from_currency
      @to_currency = to_currency
    end

    def call
      response = fetch_rate_from_api
      parse_and_save_rate(response)
    rescue StandardError => e
      Rails.logger.error("Failed to fetch currency rate: #{e.message}")
      raise RateFetchError, "Failed to fetch rate: #{e.message}"
    end

    private

    def fetch_rate_from_api
      api_key = ENV['CURRENCY_API_KEY']
      raise RateFetchError, 'Currency API key not configured' unless api_key

      currencies = [from_currency.code, to_currency.code].join(',')

      response = self.class.get('/latest', {
                                  query: {
                                    apikey: api_key,
                                    currencies: currencies
                                  },
                                  timeout: 10
                                })

      raise RateFetchError, "API request failed with status #{response.code}" unless response.success?

      response.parsed_response
    end

    def parse_and_save_rate(response_data)
      data = response_data['data']
      raise RateFetchError, 'Invalid API response format' unless data

      # Extract the rate for the target currency
      target_currency_data = data[to_currency.code]
      raise RateFetchError, "Rate not found for #{to_currency.code}" unless target_currency_data

      rate = target_currency_data['value'].to_f
      raise RateFetchError, 'Invalid rate value' unless rate.positive?

      # Save the rate to database
      CurrencyRate.create_or_update_rate(from_currency, to_currency, rate)
    end

    class RateFetchError < StandardError; end
  end
end
