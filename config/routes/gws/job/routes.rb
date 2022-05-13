Rails.application.routes.draw do
  Gws::Share::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  gws "job" do
    resources :logs, only: [:index, :show] do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      match :download_all, on: :collection, via: %i[get post]
      get :download, on: :member
    end

    resources :reservations, only: [:index, :show, :destroy], concerns: [:deletion]

    scope "user" do
      get '/' => redirect { |p, req| "#{req.path}/logs" }, as: :user_main

      resources :user_logs, path: "/logs", only: [:index, :show] do
        get :batch_destroy, on: :collection
        post :batch_destroy, on: :collection
        match :download_all, on: :collection, via: %i[get post]
        get :download, on: :member
      end

      resources :user_reservations, path: "/reservations", only: [:index, :show, :destroy], concerns: [:deletion]
    end
  end
end
