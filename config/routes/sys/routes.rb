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
    get "copy" => "copy#index", as: :copy
    post "copy/confirm" => "copy#confirm"
    post "copy/run" => "copy#run"
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
  end

end
