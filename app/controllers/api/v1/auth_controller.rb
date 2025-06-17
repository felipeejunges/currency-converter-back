# frozen_string_literal: true

module Api
  module V1
    class AuthController < Devise::SessionsController
      respond_to :json

      private

      def respond_with(resource, _opts = {})
        render json: { user: { id: resource.id, email: resource.email, name: resource.name }, token: current_token }, status: :ok
      end

      def respond_to_on_destroy
        if current_user
          render json: { message: 'Logged out successfully.' }, status: :ok
        else
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end

      def current_token
        request.env['warden-jwt_auth.token']
      end
    end
  end
end
