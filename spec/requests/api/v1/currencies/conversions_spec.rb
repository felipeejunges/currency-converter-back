require 'swagger_helper'

RSpec.describe 'api/v1/currencies/conversions', type: :request do
  path '/api/v1/currencies/conversions' do
    get('list conversions') do
      tags 'Conversions'
      operationId 'listConversions'
      security [BearerAuth: []]
      produces 'application/json'
      
      parameter name: 'page[page]', in: :query, type: :integer, required: false, description: 'Page number for pagination', example: 1
      parameter name: 'page[limit]', in: :query, type: :integer, required: false, description: 'Number of items per page', example: 20

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let!(:usd_currency) { create(:currency, :usd) }
        let!(:brl_currency) { create(:currency, :brl) }
        let!(:currency_rate) { create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency) }
        let!(:conversion) { create(:currency_conversion, user: user, currency_rate: currency_rate) }

        schema type: :object,
               properties: {
                 conversions: {
                   type: :array,
                   items: {
                     '$ref' => '#/components/schemas/Conversion'
                   }
                 },
                 pagination: {
                   '$ref' => '#/components/schemas/Pagination'
                 }
               },
               required: %w[conversions pagination]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(401, 'unauthorized') do
        let(:Authorization) { 'Bearer invalid_token' }

        schema '$ref' => '#/components/schemas/Error'

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    post('create conversion') do
      tags 'Conversions'
      operationId 'createConversion'
      security [BearerAuth: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          conversion: {
            type: :object,
            properties: {
              from_currency: { 
                type: :string, 
                example: 'USD',
                description: '3-letter currency code to convert from (BRL, USD, EUR, JPY)'
              },
              to_currency: { 
                type: :string, 
                example: 'BRL',
                description: '3-letter currency code to convert to (BRL, USD, EUR, JPY)'
              },
              from_value: { 
                type: :number, 
                format: :decimal,
                example: 100.0,
                description: 'Amount to convert (must be greater than 0)'
              },
              force_refresh: { 
                type: :boolean, 
                example: false,
                description: 'Force refresh of exchange rate (optional)'
              }
            },
            required: %w[from_currency to_currency from_value]
          }
        }
      }

      response(201, 'conversion created successfully') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        let!(:usd_currency) { create(:currency, :usd) }
        let!(:brl_currency) { create(:currency, :brl) }
        let!(:currency_rate) { create(:currency_rate, from_currency: usd_currency, to_currency: brl_currency, rate: 5.25) }
        
        let(:params) do
          {
            conversion: {
              from_currency: 'USD',
              to_currency: 'BRL',
              from_value: 100.0,
              force_refresh: false
            }
          }
        end

        before do
          allow_any_instance_of(::Currencies::ConversionService).to receive(:call).and_return(
            create(:currency_conversion, user: user, currency_rate: currency_rate, from_value: 100.0, to_value: 525.0)
          )
        end

        schema '$ref' => '#/components/schemas/Conversion'

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'invalid currency codes') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        
        let(:params) do
          {
            conversion: {
              from_currency: 'INVALID',
              to_currency: 'BRL',
              from_value: 100.0
            }
          }
        end

        schema '$ref' => '#/components/schemas/Error'

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'invalid amount') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        
        let(:params) do
          {
            conversion: {
              from_currency: 'USD',
              to_currency: 'BRL',
              from_value: -10.0
            }
          }
        end

        schema '$ref' => '#/components/schemas/Error'

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(401, 'unauthorized') do
        let(:Authorization) { 'Bearer invalid_token' }
        let(:params) do
          {
            conversion: {
              from_currency: 'USD',
              to_currency: 'BRL',
              from_value: 100.0
            }
          }
        end

        schema '$ref' => '#/components/schemas/Error'

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(500, 'internal server error') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
        
        let(:params) do
          {
            conversion: {
              from_currency: 'USD',
              to_currency: 'BRL',
              from_value: 100.0
            }
          }
        end

        before do
          allow_any_instance_of(::Currencies::ConversionService).to receive(:call).and_raise(StandardError, 'Service error')
        end

        schema '$ref' => '#/components/schemas/Error'

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
