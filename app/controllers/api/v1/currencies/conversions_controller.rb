# frozen_string_literal: true

module Api
  module V1
    module Currencies
      class ConversionsController < ApplicationController
        before_action :authenticate_user!
        before_action :set_currencies, only: [:post]

        def post
          @conversion = Currency::ConversionService.new(
            user: current_user,
            from_currency: @from_currency,
            to_currency: @to_currency,
            from_value: conversion_params[:from_value],
            force_refresh: conversion_params[:force_refresh] == 'true'
          ).call
        rescue Currency::ConversionService::ConversionError => e
          render json: { error: e.message }, status: :unprocessable_entity
        rescue StandardError => e
          Rails.logger.error("Conversion error: #{e.message}")
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        def index
          @conversions = Currency::Conversion.for_user(current_user).recent
          @pagy, @conversions = pagy(@conversions.distinct(:id))
          @pagination = pagy_metadata(@pagy)
        end

        private

        def conversion_params
          params.permit(:from_currency, :to_currency, :from_value, :force_refresh)
        end

        def set_currencies
          @from_currency = Currency.find_by_code(conversion_params[:from_currency])
          @to_currency = Currency.find_by_code(conversion_params[:to_currency])

          unless @from_currency&.supported?
            render json: { error: "Unsupported from_currency: #{conversion_params[:from_currency]}" },
                   status: :unprocessable_entity
            return
          end

          return if @to_currency&.supported?

          render json: { error: "Unsupported to_currency: #{conversion_params[:to_currency]}" },
                 status: :unprocessable_entity
        end
      end
    end
  end
end
