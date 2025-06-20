require 'rails_helper'

RSpec.describe CurrencyRateFetcherJob, type: :job do
  let(:usd) { create(:currency, :usd) }
  let(:brl) { create(:currency, :brl) }
  let(:eur) { create(:currency, :eur) }
  let(:jpy) { create(:currency, :jpy) }
  let(:rate_fetcher_service) { instance_double(Currency::RateFetcherService) }

  before do
    allow(Currency::RateFetcherService).to receive(:new).and_return(rate_fetcher_service)
    allow(rate_fetcher_service).to receive(:call)
  end

  describe '#perform' do
    it 'fetches rates for all supported currency combinations' do
      expect(Currency::RateFetcherService).to receive(:new).exactly(12).times.and_return(rate_fetcher_service)
      expect(rate_fetcher_service).to receive(:call).exactly(12).times

      described_class.perform_now
    end

    it 'skips same currency combinations' do
      described_class.perform_now

      expect(Currency::RateFetcherService).not_to have_received(:new).with(
        from_currency: usd,
        to_currency: usd
      )
    end

    it 'logs the start and completion of the job' do
      expect(Rails.logger).to receive(:info).with('Starting to fetch rates for 12 currency combinations')
      expect(Rails.logger).to receive(:info).with('Completed currency rate fetching job')

      described_class.perform_now
    end

    it 'logs successful rate fetches' do
      expect(Rails.logger).to receive(:info).with(/Successfully fetched rate for USD -> BRL/)

      described_class.perform_now
    end

    context 'when rate fetching fails for some combinations' do
      before do
        allow(rate_fetcher_service).to receive(:call).and_raise(StandardError, 'API Error')
      end

      it 'continues processing other combinations' do
        expect(Rails.logger).to receive(:error).exactly(12).times.with(/Failed to fetch rate for .*: API Error/)
        expect(Rails.logger).to receive(:info).with('Completed currency rate fetching job')

        described_class.perform_now
      end
    end
  end
end 