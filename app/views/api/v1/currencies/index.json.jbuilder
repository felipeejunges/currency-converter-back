# frozen_string_literal: true

json.currencies @currencies do |currency|
  json.partial! 'api/v1/currencies/currency', currency: currency
end
