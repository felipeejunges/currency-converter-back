# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Currency Converter API',
        description: 'A comprehensive API for currency conversion with real-time exchange rates. Uses JSONAPI-style pagination with page[page] and page[limit] parameters.',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        }
      ],
      components: {
        securitySchemes: {
          BearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT',
            description: 'JWT token obtained from login endpoint'
          }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              email: { type: :string, format: :email, example: 'user@example.com' },
              name: { type: :string, example: 'John Doe' }
            },
            required: %w[id email name]
          },
          UserRegistration: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              email: { type: :string, format: :email, example: 'user@example.com' },
              first_name: { type: :string, example: 'John' },
              last_name: { type: :string, example: 'Doe' },
              full_name: { type: :string, example: 'John Doe' }
            },
            required: %w[id email first_name last_name full_name]
          },
          Currency: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              code: { type: :string, example: 'USD', description: '3-letter currency code' },
              name: { type: :string, example: 'US Dollar' },
              symbol: { type: :string, example: '$' },
              symbol_native: { type: :string, example: '$' }
            },
            required: %w[id code name symbol symbol_native]
          },
          Conversion: {
            type: :object,
            properties: {
              transaction_id: { type: :integer, example: 1 },
              user_id: { type: :integer, example: 1 },
              from_currency: { type: :string, example: 'USD' },
              to_currency: { type: :string, example: 'BRL' },
              from_value: { type: :string, example: '100.0' },
              to_value: { type: :string, example: '525.0' },
              rate: { type: :string, example: '5.25' },
              timestamp: { type: :string, format: 'date-time', example: '2024-01-01T12:00:00Z' }
            },
            required: %w[transaction_id user_id from_currency to_currency from_value to_value rate timestamp]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Error message' },
              details: { 
                type: :array, 
                items: { type: :string },
                example: ['Email is invalid', 'Password is too short']
              }
            }
          },
          Pagination: {
            type: :object,
            properties: {
              count: { type: :integer, example: 100 },
              page: { type: :integer, example: 1 },
              limit: { type: :integer, example: 20 },
              pages: { type: :integer, example: 5 },
              last: { type: :integer, example: 5 },
              next: { type: [:integer, :null], example: 2 },
              prev: { type: [:integer, :null], example: nil },
              from: { type: :integer, example: 1 },
              to: { type: :integer, example: 20 },
              vars: { type: :object },
              series: { type: :array, items: { type: :string } }
            },
            description: 'Pagination metadata. Use page[page] and page[limit] query parameters for pagination.'
          }
        }
      },
      tags: [
        {
          name: 'Authentication',
          description: 'User authentication and registration endpoints'
        },
        {
          name: 'Currencies',
          description: 'Currency management and listing endpoints'
        },
        {
          name: 'Conversions',
          description: 'Currency conversion operations with JSONAPI-style pagination'
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
