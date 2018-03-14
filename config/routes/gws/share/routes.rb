SS::Application.routes.draw do
  Gws::Share::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :export do
    get :view, on: :member
    get :thumb, on: :member
    get :download, on: :member
  end

  concern :lock do
    get :lock, :on => :member
    delete :lock, action: :unlock, :on => :member
  end

  gws "share" do
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

    # with folder
    scope(path: "folder-:folder", as: "folder") do
      resources :files, concerns: [:deletion, :export] do
        post :disable, on: :member
        post :download_all, on: :collection
        post :disable_all, on: :collection
      end
    end

    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
      get "folders/:mode" => "folders#index", as: 'folders'
      get "folder_list" => "folder_list#index"
    end

    namespace "management" do
      resources :files, concerns: [:deletion, :export] do
        post :active, on: :member
        get :recover, on: :member
        post :active_all, on: :collection
      end
      scope(path: "folder-:folder", as: "folder") do
        resources :files, concerns: [:deletion, :export] do
          post :active, on: :member
          get :recover, on: :member
          post :active_all, on: :collection
        end
      end
      resources :categories, concerns: [:deletion]
    end
  end
end
