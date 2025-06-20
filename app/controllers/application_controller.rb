# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pagy::Backend
  rescue_from ActiveRecord::RecordNotFound, with: :raise_bad_request

  private

  def authenticate_user!
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end

  def set_default_response_format
    request.format = :json
  end

  def raise_bad_request
    render json: { error: 'Record not found' }, status: :not_found
  end
end
