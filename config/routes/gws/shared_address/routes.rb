SS::Application.routes.draw do
  Gws::SharedAddress::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
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
      resources :addresses, concerns: [:soft_deletion, :export], except: [:destroy]
      resources :trashes, concerns: [:deletion, :export], except: [:new, :create, :edit, :update] do
        match :undo_delete, on: :member, via: [:get, :post]
      end

      scope(path: "group-:group", as: "group") do
        resources :addresses, concerns: [:deletion, :export]
      end
    end

    namespace "apis" do
      get "addresses" => "addresses#index"
    end
  end
end
