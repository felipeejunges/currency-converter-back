# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Currencies::Conversions API', type: :request do
  let(:user) { create(:user) }
  let(:usd_currency) { create(:currency, :usd) }
  let(:brl_currency) { create(:currency, :brl) }
  let(:currency_rate) { create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency, rate: 5.25) }

  before do
    sign_in user
  end

  describe 'GET /api/v1/currencies/conversions' do
    let!(:conversion1) { create(:currency_conversion, user: user, currency_rate: currency_rate, created_at: 1.day.ago) }
    let!(:conversion2) { create(:currency_conversion, user: user, currency_rate: currency_rate, created_at: 2.days.ago) }
    let!(:conversion3) { create(:currency_conversion, user: user, currency_rate: currency_rate, created_at: 3.days.ago) }

    it 'returns paginated conversions with pagination metadata' do
      get '/api/v1/currencies/conversions'

      expect(response).to have_http_status(:ok)
      
      json_response = JSON.parse(response.body)
      
      expect(json_response['conversions']).to be_an(Array)
      expect(json_response['conversions'].length).to be > 0

      conversion = json_response['conversions'].first
      expect(conversion).to include(
        'transaction_id',
        'user_id',
        'from_currency',
        'to_currency',
        'from_value',
        'to_value',
        'rate',
        'timestamp'
      )

      expect(json_response['pagination']).to be_present
      expect(json_response['pagination']).to include(
        'page',
        'count',
        'limit',
        'pages'
      )
    end

    it 'returns only conversions for the authenticated user' do
      other_user = create(:user)
      other_conversion = create(:currency_conversion, user: other_user, currency_rate: currency_rate)

      get '/api/v1/currencies/conversions'

      json_response = JSON.parse(response.body)
      user_ids = json_response['conversions'].map { |c| c['user_id'] }
      
      expect(user_ids).to all(eq(user.id))
      expect(user_ids).not_to include(other_user.id)
    end

    it 'orders conversions by created_at descending' do
      get '/api/v1/currencies/conversions'

      json_response = JSON.parse(response.body)
      timestamps = json_response['conversions'].map { |c| Time.parse(c['timestamp']) }
      
      expect(timestamps).to eq(timestamps.sort.reverse)
    end

    it 'includes related currency rates and currencies' do
      get '/api/v1/currencies/conversions'

      json_response = JSON.parse(response.body)
      
      expect(json_response['currency_rates']).to be_an(Array)
      expect(json_response['currencies']).to be_an(Array)
      
      expect(json_response['currency_rates'].length).to be > 0
      expect(json_response['currencies'].length).to be > 0
    end
  end

  describe 'POST /api/v1/currencies/conversions', :vcr do
    let(:valid_params) do
      {
        from_currency: 'USD',
        to_currency: 'BRL',
        from_value: 100.0,
        force_refresh: false
      }
    end

    context 'when conversion is successful' do
      it 'creates a new conversion and returns the result' do
        expect {
          post '/api/v1/currencies/conversions', params: valid_params
        }.to change(Currency::Conversion, :count).by(1)

        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'transaction_id',
          'user_id',
          'from_currency',
          'to_currency',
          'from_value',
          'to_value',
          'rate',
          'timestamp'
        )

        expect(json_response['user_id']).to eq(user.id)
        expect(json_response['from_currency']).to eq('USD')
        expect(json_response['to_currency']).to eq('BRL')
        expect(json_response['from_value']).to eq('100.0')
        expect(json_response['to_value']).to be_present
        expect(json_response['rate']).to be_present
      end
    end

    context 'when from_currency is not supported' do
      it 'returns an error' do
        post '/api/v1/currencies/conversions', params: valid_params.merge(from_currency: 'INVALID')

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Unsupported from_currency: INVALID')
      end
    end

    context 'when to_currency is not supported' do
      it 'returns an error' do
        post '/api/v1/currencies/conversions', params: valid_params.merge(to_currency: 'INVALID')

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Unsupported to_currency: INVALID')
      end
    end

    context 'when force_refresh is true' do
      it 'forces a fresh rate fetch' do
        post '/api/v1/currencies/conversions', params: valid_params.merge(force_refresh: true)

        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response).to include('transaction_id', 'rate')
      end
    end

    context 'when API request fails' do
      before do
        allow_any_instance_of(Currencies::RateFetcherService).to receive(:call).and_raise(
          Currencies::RateFetcherService::RateFetchError, 'API request failed'
        )
      end

      it 'returns an error response' do
        post '/api/v1/currencies/conversions', params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('API request failed')
      end
    end

    context 'when user is not authenticated' do
      before { sign_out user }

      it 'returns unauthorized' do
        post '/api/v1/currencies/conversions', params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end 