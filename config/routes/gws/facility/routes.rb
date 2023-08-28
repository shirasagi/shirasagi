Rails.application.routes.draw do
  Gws::Facility::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  gws "facility" do
    resources :columns, path: 'items/:form_id/columns', concerns: [:deletion] do
      get :input_form, on: :collection
    end
    resources :items, concerns: [:deletion, :import] do
      match :download_all, on: :collection, via: %i[get post]
    end
    resources :categories, concerns: [:deletion]
    namespace :usage do
      get '/' => 'main#index', as: :main
      resources :yearly, only: [:index], path: 'yearly/:yyyy', yyyy: %r{\d{4}} do
        post :download, on: :collection
      end
      resources :monthly, only: [:index], path: 'monthly/:yyyymm', yyyymm: %r{\d{6}} do
        post :download, on: :collection
      end
    end
    namespace :state do
      get '/' => 'main#index', as: :main
      resources :daily, only: [:index], path: 'daily/:yyyymmdd', yyyymmdd: %r{\d{8}} do
        post :download, on: :collection
      end
    end
  end
end
