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

  gws "share" do
    resources :files, concerns: [:deletion, :export] do
      get :download_history, on: :member
    end

    resources :folders, concerns: [:deletion, :export]

    # with folder
    scope(path: "folder-:folder", as: "folder") do
      resources :files, concerns: [:deletion, :export]
    end

    resource :setting, only: [:show, :edit, :update]
    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "folders" => "folders#index"
    end

    namespace "apis" do
      get "categories" => "categories#index"
    end

  end
end
