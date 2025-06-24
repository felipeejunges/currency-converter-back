# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < ApplicationController
      def create
        @user = User.new(user_params)

        if @user.save
          render :create, status: :created, formats: [:json]
        else
          render :error, status: :unprocessable_entity, formats: [:json]
        end
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
      end
    end
  end
end
