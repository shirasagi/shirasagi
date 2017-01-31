SS::Application.routes.draw do
  Gws::Share::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws "share" do
    resources :files, concerns: [:deletion] do
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
      get :categories, on: :collection
    end

    # with category
    scope(path: ":category", as: "category") do
      resources :files, concerns: [:deletion] do
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
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
