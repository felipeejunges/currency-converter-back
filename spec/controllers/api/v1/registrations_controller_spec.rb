# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Registrations API', type: :request do
  describe 'POST /api/v1/register' do
    let(:valid_params) do
      {
        user: {
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          first_name: 'John',
          last_name: 'Doe'
        }
      }
    end

    context 'when registration is successful' do
      it 'creates a new user and returns success response' do
        expect {
          post '/api/v1/register', params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('User registered successfully')
        
        user_data = json_response['user']
        expect(user_data).to include(
          'id',
          'email',
          'first_name',
          'last_name',
          'full_name'
        )
        
        expect(user_data['email']).to eq('test@example.com')
        expect(user_data['first_name']).to eq('John')
        expect(user_data['last_name']).to eq('Doe')
        expect(user_data['full_name']).to eq('John Doe')
      end

      it 'encrypts the password' do
        post '/api/v1/register', params: valid_params
        
        user = User.find_by(email: 'test@example.com')
        expect(user.encrypted_password).not_to eq('password123')
        expect(user.valid_password?('password123')).to be true
      end
    end

    context 'when email is already taken' do
      before do
        create(:user, email: 'test@example.com')
      end

      it 'returns an error' do
        post '/api/v1/register', params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include('Email has already been taken')
      end
    end

    context 'when password confirmation does not match' do
      it 'returns an error' do
        params = valid_params.deep_merge(user: { password_confirmation: 'different_password' })
        
        post '/api/v1/register', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include("Password confirmation doesn't match Password")
      end
    end

    context 'when password is too short' do
      it 'returns an error' do
        params = valid_params.deep_merge(user: { password: '123', password_confirmation: '123' })
        
        post '/api/v1/register', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include('Password is too short (minimum is 6 characters)')
      end
    end

    context 'when first_name is missing' do
      it 'returns an error' do
        params = valid_params.deep_merge(user: { first_name: '' })
        
        post '/api/v1/register', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include("First name can't be blank")
      end
    end

    context 'when last_name is missing' do
      it 'returns an error' do
        params = valid_params.deep_merge(user: { last_name: '' })
        
        post '/api/v1/register', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include("Last name can't be blank")
      end
    end

    context 'when first_name is too short' do
      it 'returns an error' do
        params = valid_params.deep_merge(user: { first_name: 'A' })
        
        post '/api/v1/register', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include('First name is too short (minimum is 2 characters)')
      end
    end

    context 'when last_name is too short' do
      it 'returns an error' do
        params = valid_params.deep_merge(user: { last_name: 'B' })
        
        post '/api/v1/register', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include('Last name is too short (minimum is 2 characters)')
      end
    end

    context 'when email is invalid' do
      it 'returns an error' do
        params = valid_params.deep_merge(user: { email: 'invalid-email' })
        
        post '/api/v1/register', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include('Email is invalid')
      end
    end

    context 'when required parameters are missing' do
      it 'returns an error for missing user parameter' do
        post '/api/v1/register', params: {}

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns an error for missing email' do
        params = valid_params.deep_merge(user: { email: '' })
        
        post '/api/v1/register', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include("Email can't be blank")
      end

      it 'returns an error for missing password' do
        params = valid_params.deep_merge(user: { password: '' })
        
        post '/api/v1/register', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
        expect(json_response['details']).to include("Password can't be blank")
      end
    end
  end
end 