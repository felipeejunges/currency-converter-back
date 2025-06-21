# frozen_string_literal: true

class CurrencyRateFetcherJob < ApplicationJob
  sidekiq_options retry: 3

  def perform
    supported_currencies = Currency.supported.to_a

    Rails.logger.info("Starting to fetch rates for #{supported_currencies.length} base currencies")

    supported_currencies.each do |from_currency|
      fetch_rates_for_currency(from_currency)
    end

    Rails.logger.info('Completed currency rate fetching job')
  end

  private

  def fetch_rates_for_currency(from_currency)
    Currencies::RateFetcherService.new(from_currency: from_currency).call

    Rails.logger.info("Successfully fetched rates for #{from_currency.code}")
  rescue StandardError => e
    Rails.logger.error("Failed to fetch rates for #{from_currency.code}: #{e.message}")
  end
end
