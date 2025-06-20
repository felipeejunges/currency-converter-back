# frozen_string_literal: true

module Api
  module V1
    class CurrenciesController < ApplicationController
      def index
        @currencies = Currency.order(:code)
        render :index, status: :ok, formats: [:json]
      end
    end
  end
end
