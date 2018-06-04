SS::Application.routes.draw do
  Gws::Board::Initializer

  concern :deletion do
    get :delete, on: :member
    #delete action: :destroy_all, on: :collection
  end

  gws "board" do
    get '/' => redirect { |p, req| "#{req.path}/-/-/topics" }, as: :main

    # with category
    scope path: ':mode/:category' do
      resources :topics, concerns: [:deletion] do
        namespace :parent, path: ":parent_id", parent_id: /\d+/ do
          resources :comments, controller: '/gws/board/comments', concerns: [:deletion]
        end
        get :categories, on: :collection
        get :print, on: :member
        post :read, on: :member
        match :soft_delete, on: :member, via: %i[get post]
        match :undo_delete, on: :member, via: %i[get post]
        post :soft_delete_all, on: :collection
      end
    end

    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
      get "browsing_states/:id" => "browsing_states#index", as: 'browsing_states'
    end
  end
end
