# coding: utf-8
SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

#  namespace "opendata", path: ".opendata" do
#    get "/" => "main#index", as: :main
#
#    resources :datasets, concerns: :deletion
#    resources :apps, concerns: :deletion
#    resources :ideas, concerns: :deletion
#  end

  content "opendata" do
    get "/" => "main#index", as: :main
    resources :datasets, concerns: :deletion
    resources :apps, concerns: :deletion
    resources :ideas, concerns: :deletion
  end

  node "opendata" do
    get "dataset/(index.:format)" => "public#index", cell: "nodes/dataset"
    get "dataset/:id/(index.:format)" => "public#show", cell: "nodes/dataset"
    get "app/(index.:format)" => "public#index", cell: "nodes/app"
    get "app/:id/(index.:format)" => "public#show", cell: "nodes/app"
    get "idea/(index.:format)" => "public#index", cell: "nodes/idea"
    get "idea/:id/(index.:format)" => "public#show", cell: "nodes/idea"
    get "sparql/*path" => "public#index", cell: "nodes/sparql"
    get "api/*path" => "public#index", cell: "nodes/api"

    get "dataset/new/(index.:format)" => "public#new", cell: "nodes/dataset"
    post "dataset/(index.:format)" => "public#create", cell: "nodes/dataset"
    get "dataset/:id/edit/(index.:format)" => "public#edit", cell: "nodes/dataset"
    patch "dataset/:id/(index.:format)" => "public#update", cell: "nodes/dataset"
    put "dataset/:id/(index.:format)" => "public#update", cell: "nodes/dataset"
    delete "dataset/:id/(index.:format)" => "public#delete", cell: "nodes/dataset"

    get "user/(index.:format)" => "public#index", cell: "nodes/user"
    get "user/:user/dataset/(index.:format)" => "public#index", cell: "nodes/user_dataset"
    get "user/:user/dataset/:id/(index.:format)" => "public#show", cell: "nodes/user_dataset"
    get "user/:user/app/(index.:format)" => "public#index", cell: "nodes/user_app"
    get "user/:user/app/:id/(index.:format)" => "public#show", cell: "nodes/user_app"
    get "user/:user/idea/(index.:format)" => "public#index", cell: "nodes/user_idea"
    get "user/:user/idea/:id/(index.:format)" => "public#show", cell: "nodes/user_idea"

    get "user/:user/dataset/new/(index.:format)" => "public#new", cell: "nodes/user_dataset"
    post "user/:user/dataset/(index.:format)" => "public#create", cell: "nodes/user_dataset"
    get "user/:user/dataset/:id/edit/(index.:format)" => "public#edit", cell: "nodes/user_dataset"
    patch "user/:user/dataset/:id/(index.:format)" => "public#update", cell: "nodes/user_dataset"
    put "user/:user/dataset/:id/(index.:format)" => "public#update", cell: "nodes/user_dataset"
    delete "user/:user/dataset/:id/(index.:format)" => "public#delete", cell: "nodes/user_dataset"

    resources :dataset, concerns: :deletion, controller: :public, cell:"nodes/dataset"
    resources :app, concerns: :deletion, controller: :public, cell:"nodes/app"
    resources :idea, concerns: :deletion, controller: :public, cell:"nodes/idea"
    resources :user do
      resources :dataset, concerns: :deletion, controller: :public, cell:"nodes/user_dataset"
      resources :app, concerns: :deletion, controller: :public, cell:"nodes/user_app"
      resources :idea, concerns: :deletion, controller: :public, cell:"nodes/user_idea"
    end
  end

#  part "opendata" do
#    get "page" => "public#index", cell: "parts/page"
#  end

#  page "opendata" do
#    get "page/:filename.:format" => "public#index", cell: "pages/page"
#  end

end
