# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Currencies::ConversionService do
  let(:user) { create(:user) }
  let(:usd_currency) { create(:currency, :usd) }
  let(:brl_currency) { create(:currency, :brl) }
  let(:from_value) { 100.0 }

  describe '#call', :vcr do
    context 'when conversion is successful' do
      let(:service) { described_class.new(user: user, from_currency: usd_currency, to_currency: brl_currency, from_value: from_value) }

      it 'creates a new conversion record' do
        expect {
          service.call
        }.to change(Currency::Conversion, :count).by(1)

        conversion = Currency::Conversion.last
        expect(conversion.user).to eq(user)
        expect(conversion.from_value).to eq(from_value)
        expect(conversion.to_value).to be > 0
        expect(conversion.currency_rate).to be_present
      end

      it 'returns the conversion object' do
        result = service.call

        expect(result).to be_a(Currency::Conversion)
        expect(result.user).to eq(user)
        expect(result.from_value).to eq(from_value)
        expect(result.to_value).to be > 0
      end

      it 'calculates to_value correctly based on rate' do
        result = service.call
        
        expected_value = (result.from_value * result.rate).round(2)
        expect(result.to_value).to eq(expected_value)
      end

      it 'uses existing rate if available and not force_refresh' do
        existing_rate = create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency, rate: 5.25)

        expect_any_instance_of(Currencies::RateFetcherService).not_to receive(:call)

        result = service.call
        expect(result.currency_rate).to eq(existing_rate)
        expect(result.to_value).to eq(from_value * 5.25)
      end

      it 'forces rate refresh when force_refresh is true' do
        existing_rate = create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency, rate: 4.0)
        service = described_class.new(user: user, from_currency: usd_currency, to_currency: brl_currency, from_value: from_value, force_refresh: true)

        expect_any_instance_of(Currencies::RateFetcherService).to receive(:call).and_call_original

        result = service.call
        expect(result.currency_rate.id).not_to eq(existing_rate.id)
        expect(result.currency_rate.rate).not_to eq(4.0)
        expect(result.currency_rate.fetched_at).to be > existing_rate.fetched_at
      end

      it 'fetches new rate when no existing rate is available' do
        expect_any_instance_of(Currencies::RateFetcherService).to receive(:call).and_call_original

        result = service.call
        expect(result.currency_rate).to be_present
        expect(result.rate).to be > 0
      end
    end

    context 'when rate fetching fails' do
      before do
        allow_any_instance_of(Currencies::RateFetcherService).to receive(:call).and_raise(
          Currencies::RateFetcherService::RateFetchError, 'API request failed'
        )
      end

      it 'raises ConversionError' do
        service = described_class.new(user: user, from_currency: usd_currency, to_currency: brl_currency, from_value: from_value)

        expect {
          service.call
        }.to raise_error(Currencies::ConversionService::ConversionError, 'API request failed')
      end
    end

    context 'when from_value is invalid' do
      it 'raises ConversionError for zero value' do
        service = described_class.new(user: user, from_currency: usd_currency, to_currency: brl_currency, from_value: 0)

        expect {
          service.call
        }.to raise_error(Currencies::ConversionService::ConversionError, 'from_value must be greater than 0')
      end

      it 'raises ConversionError for negative value' do
        service = described_class.new(user: user, from_currency: usd_currency, to_currency: brl_currency, from_value: -100)

        expect {
          service.call
        }.to raise_error(Currencies::ConversionService::ConversionError, 'from_value must be greater than 0')
      end
    end

    context 'when currencies are the same' do
      it 'raises ConversionError' do
        service = described_class.new(user: user, from_currency: usd_currency, to_currency: usd_currency, from_value: from_value)

        expect {
          service.call
        }.to raise_error(Currencies::ConversionService::ConversionError, 'Cannot convert to the same currency')
      end
    end

    context 'when currencies are not supported' do
      let(:invalid_currency) { create(:currency, code: 'XXX', name: 'Invalid Currency', symbol: 'X', symbol_native: 'X') }

      it 'raises ConversionError for unsupported from_currency' do
        service = described_class.new(user: user, from_currency: invalid_currency, to_currency: brl_currency, from_value: from_value)

        expect {
          service.call
        }.to raise_error(Currencies::ConversionService::ConversionError, 'Unsupported currency: XXX')
      end

      it 'raises ConversionError for unsupported to_currency' do
        service = described_class.new(user: user, from_currency: usd_currency, to_currency: invalid_currency, from_value: from_value)

        expect {
          service.call
        }.to raise_error(Currencies::ConversionService::ConversionError, 'Unsupported currency: XXX')
      end
    end

    context 'when rate is zero or negative' do
      before do
        allow_any_instance_of(Currencies::RateFetcherService).to receive(:call) do
          create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency, rate: 0)
        end
      end

      it 'raises ConversionError' do
        service = described_class.new(user: user, from_currency: usd_currency, to_currency: brl_currency, from_value: from_value)

        expect {
          service.call
        }.to raise_error(Currencies::ConversionService::ConversionError, 'Validation failed: Rate must be greater than 0')
      end
    end
  end

  describe 'logging', :vcr do
    let(:service) { described_class.new(user: user, from_currency: usd_currency, to_currency: brl_currency, from_value: from_value) }

    it 'logs the conversion on create' do
      expect(Rails.logger).to receive(:info).with(/Currency conversion:/)
      service.call
    end
  end
end 