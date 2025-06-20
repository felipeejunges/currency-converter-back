# frozen_string_literal: true

module Api
  module V1
    module Currencies
      class ConversionsController < ApplicationController
        before_action :authenticate_user!

        def index
          @conversions = Currency::Conversion.for_user(current_user).recent
          @pagy, @conversions = pagy(@conversions.distinct(:id))
          @pagination = pagy_metadata(@pagy)
          render :index, status: :ok, formats: [:json]
        end

        def create
          @conversion = conversion_service.call

          render :create, status: :created, formats: [:json]
        rescue ::Currencies::ConversionService::ConversionError => e
          render json: { error: e.message }, status: :unprocessable_entity
        rescue StandardError => e
          Rails.logger.error("Conversion error: #{e.message}")
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        private

        def conversion_params
          params.permit(:from_currency, :to_currency, :from_value, :force_refresh)
        end

        def conversion_service
          ::Currencies::ConversionService.new(
            user: current_user,
            from_currency: Currency.find_by_code(conversion_params[:from_currency]),
            to_currency: Currency.find_by_code(conversion_params[:to_currency]),
            from_value: conversion_params[:from_value],
            force_refresh: conversion_params[:force_refresh] == 'true'
          )
        end
      end
    end
  end
end
