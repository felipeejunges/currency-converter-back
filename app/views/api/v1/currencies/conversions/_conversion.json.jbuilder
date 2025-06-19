# frozen_string_literal: true

json.extract! conversion, :id, :from_value, :to_value, :force_refresh, :created_at, :updated_at
json.transaction_id conversion.id
json.user_id conversion.user_id
json.from_currency conversion.from_currency_code
json.to_currency conversion.to_currency_code
json.rate conversion.rate
json.timestamp conversion.timestamp.iso8601
