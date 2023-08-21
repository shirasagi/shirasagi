Rails.application.routes.draw do
  #Gws::PersonalAddress::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :export do
    match :download_all, on: :collection, via: %i[get post]
    get :download_template, on: :collection
    match :import, on: :collection, via: %i[get post]
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
