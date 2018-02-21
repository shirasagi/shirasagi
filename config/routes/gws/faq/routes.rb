SS::Application.routes.draw do
  Gws::Faq::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws "faq" do
    get '/' => redirect { |p, req| "#{req.path}/-/-/topics" }, as: :main

    # with category
    scope path: ':mode/:category' do
      resources :topics, concerns: [:deletion] do
        namespace :parent, path: ":parent_id", parent_id: /\d+/ do
          resources :comments, controller: '/gws/faq/comments', concerns: [:deletion]
        end
        get :categories, on: :collection
        post :read, on: :member
        match :soft_delete, on: :member, via: %i[get post]
        match :undo_delete, on: :member, via: %i[get post]
        post :soft_delete_all, on: :collection
      end
    end

    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
    end
  end
end
