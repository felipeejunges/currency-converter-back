# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Currencies API', type: :request do
  describe 'GET /api/v1/currencies' do
    let!(:usd_currency) { create(:currency, :usd) }
    let!(:brl_currency) { create(:currency, :brl) }
    let!(:eur_currency) { create(:currency, :eur) }
    let!(:jpy_currency) { create(:currency, :jpy) }

    it 'returns all currencies with all fields' do
      get '/api/v1/currencies'

      expect(response).to have_http_status(:ok)
      
      json_response = JSON.parse(response.body)
      expect(json_response['currencies']).to be_an(Array)
      expect(json_response['currencies'].length).to eq(4)

      currency = json_response['currencies'].first
      expect(currency).to include(
        'id',
        'code',
        'name',
        'symbol',
        'symbol_native'
      )

      currency_codes = json_response['currencies'].map { |c| c['code'] }
      expect(currency_codes).to include('USD', 'BRL', 'EUR', 'JPY')
    end

    it 'returns currencies in the correct format' do
      get '/api/v1/currencies'

      json_response = JSON.parse(response.body)
      usd = json_response['currencies'].find { |c| c['code'] == 'USD' }
      
      expect(usd).to include(
        'id' => usd_currency.id,
        'code' => 'USD',
        'name' => 'US Dollar',
        'symbol' => '$',
        'symbol_native' => '$'
      )
    end

    it 'returns currencies ordered by code' do
      get '/api/v1/currencies'

      json_response = JSON.parse(response.body)
      currency_codes = json_response['currencies'].map { |c| c['code'] }
      
      expect(currency_codes).to eq(currency_codes.sort)
    end
  end
end 