# frozen_string_literal: true

json.user do
  json.partial! 'api/v1/registrations/user', user: @user
end

json.message 'User registered successfully'
