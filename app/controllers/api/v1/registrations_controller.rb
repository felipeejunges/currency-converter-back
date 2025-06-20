# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < ApplicationController
      def create
        user = User.new(user_params)

        if user.save
          render json: {
            user: {
              id: user.id,
              email: user.email,
              first_name: user.first_name,
              last_name: user.last_name,
              full_name: user.full_name
            },
            message: 'User registered successfully'
          }, status: :created
        else
          render json: {
            error: 'Registration failed',
            details: user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
      end
    end
  end
end
