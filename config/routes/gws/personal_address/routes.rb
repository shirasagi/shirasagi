SS::Application.routes.draw do
  #Gws::PersonalAddress::Initializer

  concern :deletion do
    get :delete, on: :member
    #delete action: :destroy_all, on: :collection
  end

  concern :export do
    get :download, on: :collection
    get :download_template, on: :collection
    get :import, on: :collection
    post :import, on: :collection
  end

  gws "personal_address" do
    resources :addresses, concerns: [:deletion, :export]

    # with group
    scope(path: "group-:group", as: "group") do
      resources :addresses, concerns: [:deletion, :export]
    end

    namespace "management" do
      resources :groups, concerns: [:deletion]
    end

    namespace "apis" do
      get "addresses" => "addresses#index"
    end
  end
end
