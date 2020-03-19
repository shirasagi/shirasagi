Rails.application.routes.draw do

  Sys::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :export do
    get :download, on: :collection
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :role do
    get "role/edit" => "groups#role_edit", on: :member
    put "role" => "groups#role_update", on: :member
  end

  concern :lock_and_unlock do
    post :lock_all, on: :collection
    post :unlock_all, on: :collection
  end

  namespace "sys", path: ".sys" do
    get "/" => "main#index", as: :main
    get "site_copy" => "site_copy#index", as: :site_copy
    post "site_copy/confirm" => "site_copy#confirm"
    post "site_copy/run" => "site_copy#run"
    post "site_copy/reset_state" => "site_copy#reset_state"
    get "test" => "test#index", as: :test
    get "test/http" => "test/http#index", as: :test_http
    get "test/mail" => "test/mail#index", as: :test_mail
    post "test/mail" => "test/mail#create", as: :send_test_mail

    resource :menu_settings, only: [:show, :edit, :update]
    resource :password_policy, only: [:show, :edit, :update]
    resource :ad, only: [:show, :edit, :update]

    resources :users, concerns: [:deletion, :lock_and_unlock]
    resources :notice, concerns: :deletion
    resources :groups, concerns: [:deletion, :role]
    resources :sites, concerns: :deletion
    resources :roles, concerns: :deletion
    resources :max_file_sizes, concerns: :deletion
    resources :postal_codes, concerns: [:deletion, :export]
    resources :prefecture_codes, concerns: [:deletion, :export]
    resources :mail_logs, concerns: :deletion, only: [ :index, :show, :delete, :destroy ] do
      get :decode, on: :member
      put :decode, on: :member, action: :commit_decode
    end

    namespace "apis" do
      get "groups" => "groups#index"
      get "sites" => "sites#index"
      get "postal_codes" => "postal_codes#index"
      get "prefecture_codes" => "prefecture_codes#index"
      post "validation" => "validation#validate"
      resources :temp_files, concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
      end
    end

    namespace "db" do
      get "/" => redirect { |p, req| "#{req.path}/colls" }
      resources :colls, concerns: :deletion
      resources :docs, concerns: :deletion, path: "colls/:coll/docs"
    end

    namespace "auth" do
      get "/" => redirect { |p, req| "#{req.path}/samls" }
      resources :samls, concerns: :deletion do
        get "metadata/:id", controller: "samls/metadata", action: :show, on: :member
        get "metadata/new", controller: "samls/metadata", action: :new, on: :collection
        post "metadata", controller: "samls/metadata", action: :create, on: :collection
      end
      resources :open_id_connects, concerns: :deletion do
        get "discovery/:id", controller: "open_id_connects/discovery", action: :show, on: :member
        get "discovery/new", controller: "open_id_connects/discovery", action: :new, on: :collection
        post "discovery", controller: "open_id_connects/discovery", action: :create, on: :collection
      end
      resources :environments, concerns: :deletion
    end
  end

end
