# frozen_string_literal: true

module Api
  module V1
    class CurrenciesController < ApplicationController
      def index
        @currencies = Currency.all
      end
    end
  end
end
