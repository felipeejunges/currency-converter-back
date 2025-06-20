# Currency Converter API

A Ruby on Rails API for currency conversion using data from CurrencyAPI.

## Features

- Convert between supported currencies (BRL, USD, EUR, JPY)
- Background job to update exchange rates daily
- User authentication with Devise
- Transaction history tracking
- Optional live rate fetching
- Comprehensive test coverage

## Supported Currencies

- BRL (Brazilian Real)
- USD (US Dollar)
- EUR (Euro)
- JPY (Japanese Yen)

## Prerequisites

- Ruby 3.2.1
- PostgreSQL
- Redis
- Docker (optional)

## Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd currency-converter-back
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Configure environment variables

Create a `.env` file in the root directory or copy and replace with your variables:

```bash
# Database Configuration
DB_HOSTNAME=db
DB_USERNAME=postgres
DB_PASSWORD=password

# Redis Configuration
REDIS_URL_SIDEKIQ=redis://redis:6379/1

# CurrencyAPI.com Configuration
CURRENCY_API_KEY=your_currency_api_key_here

# Rails Configuration
RAILS_ENV=development
RAILS_SERVE_STATIC_FILES=true
```

### 4. Set up the database

```bash
# Create and migrate database
rails db:create
rails db:migrate
rails db:seed
```

### 5. Start the services

```bash
# Start Redis
redis-server

# Start Sidekiq (in a separate terminal)
bundle exec sidekiq

# Start the Rails server
rails server
```

## Docker Setup

### 1. Build and start containers

```bash
docker-compose up --build
```

### 2. Run migrations and seed data

```bash
docker-compose exec server rails db:create db:migrate db:seed
```

## API Endpoints

### Authentication

All endpoints require authentication using JWT tokens.

#### Register
```
POST /api/v1/register
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password",
    "password_confirmation": "password",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

Response:
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "full_name": "John Doe"
  },
  "message": "User registered successfully"
}
```

#### Login
```
POST /api/v1/login
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password"
  }
}
```

Response:
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe"
  },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

#### Logout
```
DELETE /api/v1/logout
Authorization: Bearer <jwt_token>
```

Response:
```json
{
  "message": "Logged out successfully."
}
```

### Currencies

#### Get All Currencies
```
GET /api/v1/currencies
Authorization: Bearer <jwt_token>
```

Response:
```json
{
  "currencies": [
    {
      "id": 1,
      "code": "USD",
      "name": "US Dollar",
      "symbol": "$",
      "symbol_native": "$"
    }
  ]
}
```

### Currency Conversion

#### Convert Currency
```
POST /api/v1/currencies/conversions
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "from_currency": "USD",
  "to_currency": "BRL",
  "from_value": 100.0,
  "force_refresh": false
}
```

Response:
```json
{
  "transaction_id": 42,
  "user_id": 123,
  "from_currency": "USD",
  "to_currency": "BRL",
  "from_value": 100.0,
  "to_value": 525.32,
  "rate": 5.2532,
  "timestamp": "2024-05-19T18:00:00Z"
}
```

#### Get Conversion History
```
GET /api/v1/currencies/conversions
Authorization: Bearer <jwt_token>
```

Response:
```json
{
  "conversions": [
    {
      "transaction_id": 42,
      "user_id": 123,
      "from_currency": "USD",
      "to_currency": "BRL",
      "from_value": 100.0,
      "to_value": 525.32,
      "rate": 5.2532,
      "timestamp": "2024-05-19T18:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "count": 1,
    "limit": 20,
    "pages": 1
  }
}
```

#### Get Transactions (Legacy Endpoint)
```
GET /api/v1/transactions
Authorization: Bearer <jwt_token>
```

## Background Jobs

The application uses Sidekiq for background job processing:

- **CurrencyRateFetcherJob**: Updates all currency combinations daily at midnight
- Runs 12 combinations (4 currencies × 3 other currencies each)

### Manual Job Execution

```bash
# Run the job manually
rails runner "CurrencyRateFetcherJob.perform_sync"
```

## Testing

### Run all tests

```bash
bundle exec rspec
```

### Run specific test files

```bash
bundle exec rspec spec/models/
bundle exec rspec spec/services/
bundle exec rspec spec/controllers/
bundle exec rspec spec/jobs/
```

## Configuration

### Environment Variables

1. Copy the example environment file:
```bash
cp env.example .env
```

2. Edit the `.env` file and add your CurrencyAPI.com key:
```bash
# Database Configuration
DB_HOSTNAME=db
DB_USERNAME=postgres
DB_PASSWORD=password

# Redis Configuration
REDIS_URL_SIDEKIQ=redis://redis:6379/1

# CurrencyAPI.com Configuration
CURRENCY_API_KEY=your_currency_api_key_here

# Rails Configuration
RAILS_ENV=development
RAILS_SERVE_STATIC_FILES=true
```

**Note**: The `.env` file is already in `.gitignore` and will not be committed to version control.

### Currency API

The application uses CurrencyAPI for exchange rates. You need to:

1. Sign up at [CurrencyAPI](https://currencyapi.com/)
2. Get your API key
3. Add it to your `.env` file as `CURRENCY_API_KEY`

**Note**: The `.env` file is already in `.gitignore` and will not be committed to version control.

### Sidekiq Configuration

Sidekiq is configured in `config/sidekiq.yaml`:

- Concurrency: 5
- Queues: default, mailers, currency_rates
- Scheduled jobs: CurrencyRateFetcherJob (daily at midnight)

## Error Handling

The API returns appropriate HTTP status codes:

- `200`: Success
- `201`: Created (conversion successful)
- `400`: Bad Request
- `401`: Unauthorized
- `422`: Unprocessable Entity
- `500`: Internal Server Error

## Logging

All currency conversions are logged with details including:
- From/to currencies and values
- Exchange rate used
- User ID
- Force refresh flag

## Code Coverage

![Code Coverage](https://github.com/user-attachments/assets/1d12ba1b-206b-445b-8cfc-db1114a4a7ce)

The project maintains comprehensive test coverage across all components including models, services, controllers, and background jobs.

## License

This project is licensed under the MIT License.
