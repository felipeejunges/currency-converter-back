# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  config.filter_sensitive_data('<CURRENCY_API_KEY>') { ENV['CURRENCY_API_KEY'] }
  config.allow_http_connections_when_no_cassette = false
  config.ignore_localhost = true

  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }

  config.before_record do |interaction|
    if interaction.request.uri.include?('api.currencyapi.com') && interaction.request.body
      interaction.request.body = interaction.request.body.gsub(ENV['CURRENCY_API_KEY'], '<CURRENCY_API_KEY>')
    end
  end
end
