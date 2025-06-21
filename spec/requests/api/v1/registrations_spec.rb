require 'swagger_helper'

RSpec.describe 'api/v1/registrations', type: :request do

  path '/api/v1/register' do

    post('create user registration') do
      tags 'Authentication'
      operationId 'createUserRegistration'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { 
                type: :string, 
                format: :email, 
                example: 'user@example.com',
                description: 'Valid email address'
              },
              password: { 
                type: :string, 
                example: 'password123',
                description: 'Password (minimum 6 characters)'
              },
              password_confirmation: { 
                type: :string, 
                example: 'password123',
                description: 'Password confirmation (must match password)'
              },
              first_name: { 
                type: :string, 
                example: 'John',
                description: 'First name (2-50 characters)'
              },
              last_name: { 
                type: :string, 
                example: 'Doe',
                description: 'Last name (2-50 characters)'
              }
            },
            required: %w[email password password_confirmation first_name last_name]
          }
        }
      }

      response(201, 'user created successfully') do
        let(:params) do
          {
            user: {
              email: 'newuser@example.com',
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'John',
              last_name: 'Doe'
            }
          }
        end

        schema type: :object,
               properties: {
                 user: {
                   '$ref' => '#/components/schemas/UserRegistration'
                 },
                 message: {
                   type: :string,
                   example: 'User registered successfully'
                 }
               },
               required: %w[user message]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:params) do
          {
            user: {
              email: 'invalid-email',
              password: '123',
              password_confirmation: 'different',
              first_name: 'A',
              last_name: 'B'
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

      response(422, 'email already taken') do
        let!(:existing_user) { create(:user, email: 'existing@example.com') }
        let(:params) do
          {
            user: {
              email: 'existing@example.com',
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'John',
              last_name: 'Doe'
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
end
