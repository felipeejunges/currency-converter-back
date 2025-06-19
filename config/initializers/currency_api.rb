# Currency API Configuration
# This initializer sets up the Currency API configuration

Rails.application.config.after_initialize do
  # Check if currency API key is configured
  unless Rails.application.credentials.currency_api_key.present?
    Rails.logger.warn "Currency API key not configured. Please add 'currency_api_key' to your credentials."
  end
end 