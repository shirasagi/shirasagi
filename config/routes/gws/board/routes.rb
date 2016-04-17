SS::Application.routes.draw do
  Gws::Board::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
  end

  gws "board" do
    resources :topics, concerns: [:deletion] do
      namespace :parent, path: ":parent_id", parent_id: /\d+/ do
        resources :comments, controller: '/gws/board/comments', concerns: [:deletion]
      end
      get :categories, on: :collection
    end

    # with category
    scope(path: ":category", as: "category") do
      resources :topics, concerns: [:deletion] do
        namespace :parent, path: ":parent_id", parent_id: /\d+/ do
          resources :comments, controller: '/gws/board/comments', concerns: [:deletion]
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
