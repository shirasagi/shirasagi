SS::Application.routes.draw do

  Sys::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, :on => :collection
  end

  concern :role do
    get "role/edit" => "groups#role_edit", :on => :member
    put "role" => "groups#role_update", :on => :member
  end

  namespace "sys", path: ".sys" do
    get "/" => "main#index", as: :main
    get "info" => "info#index", as: :info
    get "site_copy" => "site_copy#index", as: :site_copy
    post "site_copy/confirm" => "site_copy#confirm"
    post "site_copy/run" => "site_copy#run"
    get "test" => "test#index", as: :test
    get "test/http" => "test/http#index", as: :test_http
    get "test/mail" => "test/mail#index", as: :test_mail
    post "test/mail" => "test/mail#create", as: :send_test_mail

    resources :users, concerns: :deletion
    resources :groups, concerns: [:deletion, :role]
    resources :sites, concerns: :deletion
    resources :roles, concerns: :deletion
    resources :max_file_sizes, concerns: :deletion

    namespace "apis" do
      get "groups" => "groups#index"
      get "sites" => "sites#index"
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
