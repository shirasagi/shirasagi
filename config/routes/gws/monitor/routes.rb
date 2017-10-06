SS::Application.routes.draw do
  Gws::Monitor::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'monitor' do
    resources :topics, concerns: [:deletion] do
      namespace :parent, path: ":parent_id", parent_id: /\d+/ do
        resources :comments, controller: '/gws/monitor/comments', concerns: [:deletion]
      end
      get :categories, on: :collection
      post :read, on: :member

      get :public, on: :member
      get :preparation, on: :member
      get :qNA, on: :member
      post :public_all, on: :collection
      post :preparation_all, on: :collection
      post :qNA_all, on: :collection
    end

    resources :answers, concerns: [:deletion] do
      get :public, on: :member
      get :preparation, on: :member
      get :qNA, on: :member
      post :public_all, on: :collection
      post :preparation_all, on: :collection
      post :qNA_all, on: :collection
    end

    resources :admins, concerns: [:deletion] do
      get :public, on: :member
      get :preparation, on: :member
      get :qNA, on: :member
      post :public_all, on: :collection
      post :preparation_all, on: :collection
      post :qNA_all, on: :collection
    end

    # with category
    scope(path: ":category", as: "category") do
      resources :topics, concerns: [:deletion] do
        namespace :parent, path: ":parent_id", parent_id: /\d+/ do
          resources :comments, controller: '/gws/monitor/comments', concerns: [:deletion]
        end
        get :categories, on: :collection
      end
    end

    resource :setting, only: [:show, :edit, :update]
    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
    end

  end
end

