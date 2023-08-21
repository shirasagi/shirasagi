Rails.application.routes.draw do

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  namespace "service", path: ".service" do
    get "/" => "main#index", as: :main
    match "login" => "login#login", as: :login, via: [:get, :post]
    match "logout" => "login#logout", as: :logout, via: [:get, :delete]

    resource :my_accounts, only: [:show]
    resources :accounts, concerns: [:deletion]

    namespace "apis" do
      get "organizations" => "organizations#index"
      put "reload_quota/:id" => "quota#reload", as: :reload_quota
    end
  end
end
