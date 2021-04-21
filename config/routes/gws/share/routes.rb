Rails.application.routes.draw do
  Gws::Share::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :export do
    get :view, on: :member
    get :thumb, on: :member
    get :download, on: :member
  end

  concern :lock do
    get :lock, on: :member
    delete :lock, action: :unlock, on: :member
  end

  gws "share" do
    namespace "apis" do
      get "categories" => "categories#index"
      get "folders/:mode" => "folders#index", as: 'folders'
      get "folder_list" => "folder_list#index"

      get "folder_crud/new" => "folder_crud#new", as: "new_root_folder"
      post "folder_crud/" => "folder_crud#create", as: "create_root_folder"
      get "folder_crud/:parent_id/new" => "folder_crud#new", as: "new_sub_folder"
      post "folder_crud/:parent_id" => "folder_crud#create", as: "create_sub_folder"
      get "folder_crud/:id/rename" => "folder_crud#rename", as: "rename_folder"
      match "folder_crud/:id/update" => "folder_crud#update", via: [:put, :patch], as: "update_folder"
      get "folder_crud/:id/delete" => "folder_crud#delete", as: "delete_folder"
      delete "folder_crud/:id" => "folder_crud#destroy", as: "destroy_folder"
    end

    scope(path: ':category', defaults: { category: '-' }) do
      resources :files, concerns: [:deletion, :export, :lock] do
        get :download_history, on: :member
        post :disable, on: :member
        post :disable_all, on: :collection
        post :download_all, on: :collection
      end

      resources :folders, concerns: [:deletion, :export] do
        get :download_folder, on: :member
        match :move, on: :member, via: [:get, :post]
      end

      scope(path: "folder-:folder", as: "folder") do
        resources :files, concerns: [:deletion, :export] do
          post :disable, on: :member
          post :download_all, on: :collection
          post :disable_all, on: :collection
        end
      end
    end

    resources :categories, concerns: [:deletion]

    namespace "management" do
      scope(path: ':category', defaults: { category: '-' }) do
        resources :files, concerns: [:deletion, :export] do
          post :active, on: :member
          get :recover, on: :member
          get :download_history, on: :member
        end
        scope(path: "folder-:folder", as: "folder") do
          resources :files, concerns: [:deletion, :export] do
            post :active, on: :member
            get :recover, on: :member
            get :download_history, on: :member
          end
        end
      end
      resources :categories, concerns: [:deletion]
    end
  end
end
