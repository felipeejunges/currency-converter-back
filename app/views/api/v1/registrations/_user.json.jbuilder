# frozen_string_literal: true

json.extract! user, :id, :email, :first_name, :last_name
json.full_name user.full_name
