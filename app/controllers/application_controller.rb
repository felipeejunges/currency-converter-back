class ApplicationController < ActionController::API
  include Pagy::Backend
  rescue_from ActiveRecord::RecordNotFound, with: :raise_bad_request

  def raise_bad_request
    render json: { error: 'Record not found' }, status: :not_found
  end
end
