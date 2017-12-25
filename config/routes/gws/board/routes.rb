SS::Application.routes.draw do
  Gws::Board::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws "board" do
    resources :topics, concerns: [:deletion] do
      namespace :parent, path: ":parent_id", parent_id: /\d+/ do
        resources :comments, controller: '/gws/board/comments', concerns: [:deletion]
      end
      get :categories, on: :collection
      post :read, on: :member
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

    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
      get "browsing_states/:id" => "browsing_states#index", as: 'browsing_states'
    end
  end
end
