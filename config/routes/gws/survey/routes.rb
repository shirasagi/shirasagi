Rails.application.routes.draw do
  Gws::Survey::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  gws 'survey' do
    get '/' => redirect { |p, req| "#{req.path}/-/-/readables" }, as: :main

    scope path: ':folder_id/:category_id' do
      resources :readables, only: [:index] do
        resource :file, except: [:new, :create] do
          get :others, on: :collection
          get :delete, on: :member
          get :print, on: :collection
        end
      end

      resources :editables, concerns: [:soft_deletion], except: [:destroy] do
        match :publish, on: :member, via: [:get, :post]
        match :depublish, on: :member, via: [:get, :post]
        match :copy, on: :member, via: [:get, :post]
        get :preview, on: :member
        get :print, on: :member
        resources :columns, only: %i[index create] do
          post :reorder, on: :collection
        end
        resources :files, controller: 'editable_files', only: [:index] do
          match :download_all, on: :collection, via: [:get, :post]
          post :zip_all_files, on: :collection
          match :notification, on: :collection, via: [:get, :post]
          get :summary, on: :collection
        end
      end
    end

    resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
      match :undo_delete, on: :member, via: [:get, :post]
    end

    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
    end
  end
end
