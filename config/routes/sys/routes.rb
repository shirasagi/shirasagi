Rails.application.routes.draw do

  Sys::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :export do
    post :download, on: :collection
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

    resource :menu_settings, only: [:show, :edit, :update]
    resource :password_policy, only: [:show, :edit, :update]
    resource :ad, only: [:show, :edit, :update]

    resources :users, concerns: [:deletion, :lock_and_unlock] do
      match :download_all, on: :collection, via: %i[get post]
      post :reset_mfa_otp, on: :member
    end
    resources :notice, concerns: :deletion
    resources :groups, concerns: [:deletion, :role] do
      match :download_all, on: :collection, via: %i[get post]
      match :import, on: :collection, via: %i[get post]
    end
    resources :sites, concerns: :deletion
    resources :roles, concerns: :deletion
    resources :max_file_sizes, concerns: :deletion
    resources :image_resizes, concerns: :deletion
    resources :postal_codes, concerns: [:deletion, :export]
    resources :prefecture_codes, concerns: [:deletion, :export]
    resources :history_archives, concerns: [:deletion], only: [:index, :show, :destroy]
    resources :mail_logs, concerns: :deletion, only: [ :index, :show, :delete, :destroy ] do
      get :decode, on: :member
      put :decode, on: :member, action: :commit_decode
    end

    namespace "diag" do
      get "/" => "main#index", as: :main
      if Rails.env.development?
        resources :https, only: [:index]
      end
      resources :mails, only: [:index, :create]
      resource :server, only: [] do
        match :show, on: :member, via: [:get, :post, :put, :delete]
      end
      resource :app_log, only: [:show]
      resource :certificate, only: [:show, :update]
    end

    namespace "apis" do
      get "users" => "users#index"
      get "groups" => "groups#index"
      get "sites" => "sites#index"
      get "postal_codes" => "postal_codes#index"
      get "prefecture_codes" => "prefecture_codes#index"
      post "validation" => "validation#validate"
      get "cke_config" => "cke_config#index"
    end

    namespace "db" do
      get "/" => redirect { |p, req| "#{req.path}/colls" }
      resources :colls, only: [:index, :show] do
        get :info, on: :collection
      end
      resources :docs, only: [:index, :show], path: "colls/:coll/docs" do
        get :indexes, on: :collection
        get :stats, on: :collection
      end
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
      resources :oauth2_applications, concerns: :deletion
      resource :setting, only: [:show, :edit, :update]
    end
  end

end
