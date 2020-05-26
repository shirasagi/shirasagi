Rails.application.routes.draw do

  #Job::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  sys "job" do
    get "/" => redirect { |p, req| "#{req.path}/logs" }, as: :main

    resources :logs, only: [:index, :show] do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      match :download_all, on: :collection, via: %i[get post]
      get :download, on: :member
    end

    resources :logs, only: [:index, :show], path: ':ymd/logs', as: :daily_logs do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      match :download_all, on: :collection, via: %i[get post]
      get :download, on: :member
    end

    resources :tasks, only: [:index, :show, :destroy], concerns: [:deletion] do
      post :reset_state, on: :member
      get :download, on: :member
    end

    resources :reservations, only: [:index, :show, :destroy], concerns: [:deletion]
  end

  cms "job" do
    get "/" => redirect { |p, req| "#{req.path}/logs" }, as: :main

    resources :logs, only: [:index, :show] do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      match :download_all, on: :collection, via: %i[get post]
      get :download, on: :member
    end

    resources :logs, only: [:index, :show], path: ':ymd/logs', as: :daily_logs do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      match :download_all, on: :collection, via: %i[get post]
      get :download, on: :member
    end

    resources :tasks, only: [:index, :show, :destroy], concerns: [:deletion] do
      post :reset_state, on: :member
      get :download, on: :member
    end

    resources :reservations, only: [:index, :show, :destroy], concerns: [:deletion]
  end

  sns "job" do
    get "/" => redirect { |p, req| "#{req.path}/logs" }, as: :main

    resources :logs, only: [:index, :show] do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      match :download_all, on: :collection, via: %i[get post]
      get :download, on: :member
    end

    resources :logs, only: [:index, :show], path: ':ymd/logs', as: :daily_logs do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      match :download_all, on: :collection, via: %i[get post]
      get :download, on: :member
    end

    resources :reservations, only: [:index, :show, :destroy], concerns: [:deletion]

    namespace "apis" do
      # resources :logs, only: [:index, :show]
      resources :statuses, only: [:show]
    end
  end
end
