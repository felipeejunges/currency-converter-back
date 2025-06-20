require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount ActionCable.server => '/cable'
  mount Sidekiq::Web => '/sidekiq'

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
