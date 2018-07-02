SS::Application.routes.draw do
  Gws::Notice::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  gws 'notice' do
    get '/' => redirect { |p, req| "#{req.path}/-/-/readables" }, as: :main

    scope path: ':folder_id/:category_id' do
      resources :readables, only: [:index, :show] do
        post :toggle_browsed, on: :member
      end
      resources :editables, concerns: [:soft_deletion], except: [:destroy] do
        match :move, on: :member, via: [:get, :post]
        match :create_my_folder, on: :collection, via: [:get, :post]
      end
    end

    resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
      match :undo_delete, on: :member, via: [:get, :post]
    end
    resources :folders, concerns: [:deletion] do
      match :move, on: :member, via: [:get, :post]
      post :reclaim, on: :member
    end
    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
      get "folders" => "folders#index"
      get ":folder_id/:category_id/:mode/folder_list" => "folder_list#index", as: "folder_list"
      scope path: ':notice_id' do
        resources :comments, concerns: [:deletion], except: [:index, :new, :show, :destroy_all]
      end
    end
  end
end
