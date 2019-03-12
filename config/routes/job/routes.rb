SS::Application.routes.draw do

  #Job::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  sys "job" do
    get "/" => redirect { |p, req| "#{req.path}/logs" }, as: :main

    get "/logs" => "logs#index", as: :logs

    resources :logs, only: [:index, :show], path: 'logs/:ymd', as: :daily_logs do
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

    get "/logs" => "logs#index", as: :logs

    resources :logs, only: [:index, :show], path: 'logs/:ymd', as: :daily_logs do
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
end
