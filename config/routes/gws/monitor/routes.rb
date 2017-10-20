SS::Application.routes.draw do
  Gws::Monitor::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :state_change do
    post :public, on: :member
    post :preparation, on: :member
    post :question_not_applicable, on: :member
    post :answered, on: :member
    post :public_all, on: :collection
    post :preparation_all, on: :collection
    post :question_not_applicable_all, on: :collection
  end

  gws 'monitor' do
    resources :topics, concerns: [:deletion, :state_change] do
      namespace :parent, path: ":parent_id", parent_id: /\d+/ do
        resources :comments, controller: '/gws/monitor/comments', concerns: [:deletion]
      end
      get :categories, on: :collection
      post :read, on: :member
    end

    resources :answers, concerns: [:deletion, :state_change]

    resources :admins, concerns: [:deletion, :state_change] do
      get :disable, on: :member
      delete :disable_all, on: :collection
    end

    namespace "management" do
      resources :topics, concerns: [:deletion] do
        get :download, on: :member
      end
      resources :trashes, concerns: [:deletion] do
        get :active, on: :member
        post :active_all, on: :collection
      end
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

