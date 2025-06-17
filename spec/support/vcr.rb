# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
  # config.default_cassette_options = {
  #   record: :once,
  #   match_requests_on: [:method, :uri],
  #   allow_playback_repeats: true
  # }
end
