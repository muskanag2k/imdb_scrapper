Rails.application.routes.draw do
  resources :actor_movie_dbs
  resources :actor_dbs
  resources :movie_dbs
  resources :actor_movies
  resources :actors
  resources :movies
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
