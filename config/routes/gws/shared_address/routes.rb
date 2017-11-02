SS::Application.routes.draw do
  Gws::SharedAddress::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :export do
    get :download, on: :collection
    get :download_template, on: :collection
    get :import, on: :collection
    post :import, on: :collection
  end

  gws "shared_address" do
    resources :addresses, concerns: [:deletion], only: [:index, :show]

    scope(path: "group-:group", as: "group") do
      resources :addresses, concerns: [:deletion], only: [:index, :show]
    end

    namespace "management" do
      resources :groups, concerns: [:deletion]
      resources :addresses, concerns: [:deletion, :export]

      scope(path: "group-:group", as: "group") do
        resources :addresses, concerns: [:deletion, :export]
      end
    end

    namespace "apis" do
      get "addresses" => "addresses#index"
    end
  end
end
