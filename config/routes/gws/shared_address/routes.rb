Rails.application.routes.draw do
  Gws::SharedAddress::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :export do
    match :download_all, on: :collection, via: %i[get post]
    get :download_template, on: :collection
    match :import, on: :collection, via: %i[get post]
  end

  gws "shared_address" do
    resources :addresses, concerns: [:deletion], only: [:index, :show]

    scope(path: "group-:group", as: "group") do
      resources :addresses, concerns: [:deletion], only: [:index, :show]
    end

    namespace "management" do
      resources :groups, concerns: [:deletion]
      resources :addresses, concerns: [:soft_deletion, :export], except: [:destroy]
      resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
        match :undo_delete, on: :member, via: [:get, :post]
      end

      scope(path: "group-:group", as: "group") do
        resources :addresses, concerns: [:deletion, :export]
      end
    end

    namespace "apis" do
      get "addresses" => "addresses#index"
      get "multi_checkboxes" => "multi_checkboxes#index"
    end
  end
end
