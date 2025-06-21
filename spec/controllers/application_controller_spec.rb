# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      set_default_response_format
      render json: { message: 'success' }
    end

    def show
      raise ActiveRecord::RecordNotFound
    end
  end

  describe '#set_default_response_format' do
    it 'sets the request format to json' do
      get :index
      
      expect(request.format).to eq(:json)
      expect(response.content_type).to include('application/json')
    end

    it 'allows the action to render json response' do
      get :index
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('success')
    end
  end

  describe '#raise_bad_request' do
    it 'handles ActiveRecord::RecordNotFound and returns not found error' do
      get :show, params: { id: 999 }
      
      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to include('application/json')
      
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Record not found')
    end

    it 'is triggered by the rescue_from ActiveRecord::RecordNotFound' do
      rescue_handlers = ApplicationController.rescue_handlers
      record_not_found_handler = rescue_handlers.find { |handler| handler[0] == 'ActiveRecord::RecordNotFound' }
      
      expect(record_not_found_handler).to be_present
      expect(record_not_found_handler[1]).to eq(:raise_bad_request)
    end
  end

  describe 'rescue_from configuration' do
    it 'has rescue_from configured for ActiveRecord::RecordNotFound' do
      rescue_handlers = ApplicationController.rescue_handlers
      record_not_found_handler = rescue_handlers.find { |handler| handler[0] == 'ActiveRecord::RecordNotFound' }
      
      expect(record_not_found_handler).to be_present
      expect(record_not_found_handler[1]).to eq(:raise_bad_request)
    end
  end
end 