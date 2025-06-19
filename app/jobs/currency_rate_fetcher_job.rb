# frozen_string_literal: true

class CurrencyRateFetcherJob < ApplicationJob
  sidekiq_options retry: 3

  def perform
    supported_currencies = Currency.supported.to_a
    combinations = generate_currency_combinations(supported_currencies)

    Rails.logger.info("Starting to fetch rates for #{combinations.length} currency combinations")

    combinations.each do |from_currency, to_currency|
      next if from_currency == to_currency

      begin
        Currency::RateFetcherService.new(
          from_currency: from_currency,
          to_currency: to_currency
        ).call

        Rails.logger.info("Successfully fetched rate for #{from_currency.code} -> #{to_currency.code}")
      rescue StandardError => e
        Rails.logger.error("Failed to fetch rate for #{from_currency.code} -> #{to_currency.code}: #{e.message}")
      end
    end

    Rails.logger.info('Completed currency rate fetching job')
  end

  private

  def generate_currency_combinations(currencies)
    currencies.product(currencies).reject { |from, to| from == to }
  end
end
