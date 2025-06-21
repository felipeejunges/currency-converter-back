require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  
  # Only mount Sidekiq web UI in development and test environments
  unless Rails.env.production?
    mount Sidekiq::Web => '/sidekiq'
  end
  
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  devise_for :users, skip: [:sessions, :registrations, :passwords]

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post 'login', to: 'auth#create'
        delete 'logout', to: 'auth#destroy'
      end

      post 'register', to: 'registrations#create'

      resources :currencies, only: [:index] do
        collection do
          resources :conversions, only: [:index, :create], controller: 'currencies/conversions'
        end
      end

      get 'transactions', to: 'conversion#index'
    end
  end
end
