# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Currencies::RateFetcherService do
  let(:usd_currency) { create(:currency, :usd) }
  let(:brl_currency) { create(:currency, :brl) }
  let(:eur_currency) { create(:currency, :eur) }
  let(:jpy_currency) { create(:currency, :jpy) }
  let(:service) { described_class.new(from_currency: usd_currency) }

  describe '#call', :vcr do
    context 'when API request is successful' do
      before do
        usd_currency
        brl_currency
        eur_currency
        jpy_currency
      end

      it 'fetches and saves all exchange rates for the base currency' do
        expect {
          service.call
        }.to change(CurrencyRate, :count).by(3)

        rates = CurrencyRate.last(3)
        expect(rates.map(&:from_currency)).to all(eq(usd_currency))
        expect(rates.map(&:to_currency)).to contain_exactly(brl_currency, eur_currency, jpy_currency)
        expect(rates.map(&:rate)).to all(be > 0)
        expect(rates.map(&:fetched_at)).to all(be_present)
      end

      it 'creates new rate records (does not update existing ones)' do
        create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency, rate: 4.0)
        create(:currency_rate, from_currency: usd_currency, to_currency: eur_currency, rate: 0.8)

        expect {
          service.call
        }.to change(CurrencyRate, :count).by(3)

        expect(CurrencyRate.where(from_currency: usd_currency, to_currency: brl_currency).count).to eq(2)
        expect(CurrencyRate.where(from_currency: usd_currency, to_currency: eur_currency).count).to eq(2)
      end

      it 'handles different base currencies' do
        service = described_class.new(from_currency: eur_currency)

        expect {
          service.call
        }.to change(CurrencyRate, :count).by(3)

        rates = CurrencyRate.last(3)
        expect(rates.map(&:from_currency)).to all(eq(eur_currency))
        expect(rates.map(&:to_currency)).to contain_exactly(usd_currency, brl_currency, jpy_currency)
        expect(rates.map(&:rate)).to all(be > 0)
      end
    end

    context 'when API key is not configured' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('CURRENCY_API_KEY').and_return(nil)
      end

      it 'raises RateFetchError' do
        expect {
          service.call
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, 'Failed to fetch rates: Currency API key not configured')
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
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, 'Failed to fetch rates: API request failed with status 500')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to fetch currency rates:/)
        
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
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, 'Failed to fetch rates: Invalid API response format')
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
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, 'Failed to fetch rates: Invalid rate value for BRL')
      end
    end

    context 'when network timeout occurs' do
      before do
        allow(service.class).to receive(:get).and_raise(Net::ReadTimeout.new('timeout'))
      end

      it 'raises RateFetchError' do
        expect {
          service.call
        }.to raise_error(Currencies::RateFetcherService::RateFetchError, /Failed to fetch rates:/)
      end
    end
  end

  describe 'API request format' do
    before do
      usd_currency
      brl_currency
      eur_currency
      jpy_currency
    end

    it 'makes request with correct parameters' do
      expect(service.class).to receive(:get).with(
        '/latest',
        {
          query: {
            apikey: ENV['CURRENCY_API_KEY'],
            currencies: 'BRL,EUR,JPY',
            base_currency: 'USD'
          },
          timeout: 10
        }
      ).and_return(
        instance_double(HTTParty::Response, success?: true, parsed_response: { 
          'data' => { 
            'BRL' => { 'value' => 5.25 },
            'EUR' => { 'value' => 0.85 },
            'JPY' => { 'value' => 150.0 }
          } 
        })
      )

      service.call
    end

    it 'uses from_currency as base_currency in API request' do
      service = described_class.new(from_currency: eur_currency)
      
      expect(service.class).to receive(:get).with(
        '/latest',
        {
          query: {
            apikey: ENV['CURRENCY_API_KEY'],
            currencies: 'USD,BRL,JPY',
            base_currency: 'EUR'
          },
          timeout: 10
        }
      ).and_return(
        instance_double(HTTParty::Response, success?: true, parsed_response: { 
          'data' => { 
            'USD' => { 'value' => 1.18 },
            'BRL' => { 'value' => 6.18 },
            'JPY' => { 'value' => 176.47 }
          } 
        })
      )

      service.call
    end
  end
end 