# frozen_string_literal: true

json.conversions @conversions do |conversion|
  json.partial! 'api/v1/currency/conversion/conversion', conversion: conversion
end

json.currency_rates @conversions.map(&:currency_rate).uniq do |currency_rate|
  json.partial! 'api/v1/currency_rates/currency_rate', currency_rate: currency_rate
end

json.currencies @conversions.map(&:from_currency).uniq + @conversions.map(&:to_currency).uniq do |currency|
  json.partial! 'api/v1/currencies/currency', currency: currency
end
