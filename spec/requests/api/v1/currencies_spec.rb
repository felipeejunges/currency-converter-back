require 'swagger_helper'

RSpec.describe 'api/v1/currencies', type: :request do

  path '/api/v1/currencies' do

    get('list currencies') do
      tags 'Currencies'
      operationId 'listCurrencies'
      produces 'application/json'

      response(200, 'successful') do
        let!(:usd_currency) { create(:currency, :usd) }
        let!(:brl_currency) { create(:currency, :brl) }
        let!(:eur_currency) { create(:currency, :eur) }
        let!(:jpy_currency) { create(:currency, :jpy) }

        schema type: :object,
               properties: {
                 currencies: {
                   type: :array,
                   items: {
                     '$ref' => '#/components/schemas/Currency'
                   }
                 }
               },
               required: %w[currencies]

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
