# frozen_string_literal: true

json.conversions @conversions do |conversion|
  json.partial! 'api/v1/currencies/conversions/conversion', conversion: conversion
end

json.partial! 'api/v1/shared/pagination'
