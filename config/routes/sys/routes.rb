SS::Application.routes.draw do

  Sys::Initializer

  concern :deletion do
    get :delete, :on => :member
  end

  namespace "sys", path: ".sys" do
    get "/" => "main#index", as: :main
    get "info" => "info#index", as: :info
    get "test" => "test#index", as: :test
    get "test/http" => "test/http#index", as: :test_http
    get "test/mail" => "test/mail#index", as: :test_mail
    post "test/mail" => "test/mail#create", as: :send_test_mail

    resources :users, concerns: :deletion
    resources :groups, concerns: :deletion
    resources :sites, concerns: :deletion
    resources :roles, concerns: :deletion
    get "/search_groups" => "search_groups#index"

    namespace "db" do
      get "/" => "main#index"
      resources :colls, concerns: :deletion
      resources :docs, concerns: :deletion, path: "colls/:coll/docs"
    end
  end

end
