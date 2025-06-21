require 'swagger_helper'

RSpec.describe 'api/v1/auth', type: :request do

  path '/api/v1/login' do
    post('login user') do
      tags 'Authentication'
      operationId 'loginUser'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: 'user@example.com' },
              password: { type: :string, example: 'password123' }
            },
            required: %w[email password]
          }
        }
      }

      response(200, 'successful login') do
        let(:user) { create(:user) }
        let(:params) do
          {
            user: {
              email: user.email,
              password: 'password123'
            }
          }
        end

        schema type: :object,
               properties: {
                 user: {
                   '$ref' => '#/components/schemas/User'
                 },
                 token: {
                   type: :string,
                   description: 'JWT authentication token',
                   example: 'eyJhbGciOiJIUzI1NiJ9...'
                 }
               },
               required: %w[user token]

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
        let(:params) do
          {
            user: {
              email: 'invalid@example.com',
              password: 'wrongpassword'
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

      response(401, 'unprocessable entity') do
        let(:params) do
          {
            user: {
              email: '',
              password: ''
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
    end
  end

  path '/api/v1/logout' do
    delete('logout user') do
      tags 'Authentication'
      operationId 'logoutUser'
      security [BearerAuth: []]
      produces 'application/json'

      response(200, 'successful logout') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

        schema type: :object,
               properties: {
                 message: {
                   type: :string,
                   example: 'Logged out successfully.'
                 }
               },
               required: %w[message]

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
