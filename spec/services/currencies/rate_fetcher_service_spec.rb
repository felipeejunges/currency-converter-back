# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Currencies::RateFetcherService do
  let(:usd_currency) { create(:currency, :usd) }
  let(:brl_currency) { create(:currency, :brl) }
  let(:service) { described_class.new(from_currency: usd_currency, to_currency: brl_currency) }

  describe '#call', :vcr do
    context 'when API request is successful' do
      it 'fetches and saves the exchange rate' do
        expect {
          service.call
        }.to change(CurrencyRate, :count).by(1)

        rate = CurrencyRate.last
        expect(rate.from_currency).to eq(usd_currency)
        expect(rate.to_currency).to eq(brl_currency)
        expect(rate.rate).to be_a(BigDecimal)
        expect(rate.rate).to be > 0
        expect(rate.fetched_at).to be_present
      end

      it 'updates existing rate if it already exists' do
        existing_rate = create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency, rate: 4.0)

        expect {
          service.call
        }.not_to change(CurrencyRate, :count)

        existing_rate.reload
        expect(existing_rate.rate).not_to eq(4.0)
        expect(existing_rate.rate).to be > 0
      end

      it 'handles different currency pairs' do
        eur_currency = create(:currency, :eur)
        service = described_class.new(from_currency: eur_currency, to_currency: usd_currency)

        expect {
          service.call
        }.to change(CurrencyRate, :count).by(1)

        rate = CurrencyRate.last
        expect(rate.from_currency).to eq(eur_currency)
        expect(rate.to_currency).to eq(usd_currency)
        expect(rate.rate).to be > 0
      end
    end

    context 'when API key is not configured' do
      before do
        allow(ENV).to receive(:[]).with('CURRENCY_API_KEY').and_return(nil)
      end

      it 'raises RateFetchError' do
        expect {
          service.call
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, 'Currency API key not configured')
      end
    end

    context 'when API request fails' do
      before do
        allow(service.class).to receive(:get).and_return(
          instance_double(HTTParty::Response, success?: false, code: 500)
        )
      end

      it 'raises RateFetchError' do
        expect {
          service.call
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, 'API request failed with status 500')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to fetch currency rate:/)
        
        expect {
          service.call
        }.to raise_error(Currencies::RateFetcherService::RateFetchError)
      end
    end

    context 'when API returns invalid response format' do
      before do
        allow(service.class).to receive(:get).and_return(
          instance_double(HTTParty::Response, success?: true, parsed_response: { 'invalid' => 'format' })
        )
      end

      it 'raises RateFetchError' do
        expect {
          service.call
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, 'Invalid API response format')
      end
    end

    context 'when API response does not contain target currency' do
      before do
        allow(service.class).to receive(:get).and_return(
          instance_double(HTTParty::Response, success?: true, parsed_response: { 'data' => { 'USD' => { 'value' => 1.0 } } })
        )
      end

      it 'raises RateFetchError' do
        expect {
          service.call
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, 'Rate not found for BRL')
      end
    end

    context 'when API returns invalid rate value' do
      before do
        allow(service.class).to receive(:get).and_return(
          instance_double(HTTParty::Response, success?: true, parsed_response: { 'data' => { 'BRL' => { 'value' => 0 } } })
        )
      end

      it 'raises RateFetchError' do
        expect {
          service.call
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, 'Invalid rate value')
      end
    end

    context 'when network timeout occurs' do
      before do
        allow(service.class).to receive(:get).and_raise(Net::ReadTimeout.new('timeout'))
      end

      it 'raises RateFetchError' do
        expect {
          service.call
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, /Failed to fetch rate:/)
      end
    end
  end

  describe 'API request format' do
    it 'makes request with correct parameters' do
      expect(service.class).to receive(:get).with(
        '/latest',
        {
          query: {
            apikey: ENV['CURRENCY_API_KEY'],
            currencies: 'USD,BRL'
          },
          timeout: 10
        }
      ).and_return(
        instance_double(HTTParty::Response, success?: true, parsed_response: { 'data' => { 'BRL' => { 'value' => 5.25 } } })
      )

      service.call
    end
  end
end 