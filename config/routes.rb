Rails.application.routes.draw do

  namespace :api do
    namespace :v1 do

      require 'sidekiq/web'
      mount Sidekiq::Web => "/sidekiq"

      resources :background_jobs, only: [:show]

      # get 'background_jobs', to: 'background_jobs#show'
      get 'login', to: 'logins#create'
      post 'dashboard', to: 'users#create'
      post 'events', to: 'users#show'
      post 'favorite_venues', to: 'user_venues#create'
      post 'get_favorite_venues', to: 'user_venues#show'
      delete 'favorite_venues/:id', to: 'user_venues#destroy'
      post 'get_user', to: 'logins#show'
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
